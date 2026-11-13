import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../import/domain/document_import_service.dart';
import '../../library/domain/document.dart';
import '../../library/domain/document_file_store.dart';
import '../../library/domain/document_repository.dart';
import '../domain/transfer_invitation.dart';
import '../domain/transfer_limits.dart';
import '../domain/transfer_manifest.dart';
import '../domain/transfer_protocol.dart';
import '../domain/transfer_repository.dart';
import '../domain/transfer_service.dart';
import '../domain/transfer_task.dart';
import 'incoming_transfer_handler.dart';
import 'transfer_connection.dart';

enum _ApprovalOutcome { accepted, rejected, disconnected, timedOut }

class _OutgoingSession {
  Socket? socket;
  String? cancelReason;
}

class _PreparedPeer {
  _PreparedPeer({
    required this.id,
    required this.connection,
    required this.socket,
    required this.deviceName,
    required this.address,
    required this.port,
  });

  final String id;
  final TransferConnection connection;
  final Socket socket;
  final String deviceName;
  final String address;
  final int port;
  Timer? closeTimer;

  Future<void> close() async {
    closeTimer?.cancel();
    closeTimer = null;
    await connection.close();
  }
}

class _OutgoingHandshake {
  const _OutgoingHandshake({
    required this.connection,
    required this.socket,
    required this.deviceName,
    required this.address,
    required this.port,
  });

  final TransferConnection connection;
  final Socket socket;
  final String deviceName;
  final String address;
  final int port;
}

class _LoadedDocument {
  const _LoadedDocument({
    required this.document,
    required this.manifest,
    required this.file,
  });

  final Document document;
  final TransferManifest manifest;
  final File file;
}

class _IncomingSession {
  _IncomingSession({
    required this.id,
    required this.manifest,
    required this.peerName,
    required this.tempFileName,
    required this.connection,
    required this.socket,
  });

  final String id;
  final TransferManifest manifest;
  final String peerName;
  final String tempFileName;
  final TransferConnection connection;
  final Socket socket;
  final Completer<bool> approval = Completer<bool>();
  String? cancelReason;
  bool waitingForApproval = true;
}

class _TransferFailure implements Exception {
  const _TransferFailure(this.message, {this.code = 'transfer_failed'});

  final String message;
  final String code;

  @override
  String toString() => message;
}

class _TransferCancelled implements Exception {
  const _TransferCancelled(this.reason);

  final String reason;

  @override
  String toString() => reason;
}

class _DigestCapture implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) {
    value = data;
  }

  @override
  void close() {}
}

/// Real TCP transport for direct transfers between two Relay installations on
/// the same IPv4 local network.
///
/// The receiver is a short-lived foreground server. The sender connects using
/// the address, port, and six-digit code displayed by the receiver. No discovery,
/// cloud relay, background service, or arbitrary sender file access is used.
class RelayTransferService implements TransferService {
  RelayTransferService({
    required TransferRepository repository,
    required DocumentRepository documentRepository,
    required DocumentFileStore fileStore,
    required IncomingTransferHandler incomingHandler,
    required Directory temporaryDirectory,
    required String deviceName,
    required TransferLimits limits,
  }) : _repository = repository,
       _documentRepository = documentRepository,
       _fileStore = fileStore,
       _incomingHandler = incomingHandler,
       _temporaryDirectory = temporaryDirectory,
       _deviceName = _safePeerName(deviceName),
       _limits = limits;

  final TransferRepository _repository;
  final DocumentRepository _documentRepository;
  final DocumentFileStore _fileStore;
  final IncomingTransferHandler _incomingHandler;
  final Directory _temporaryDirectory;
  final String _deviceName;
  final TransferLimits _limits;
  final Random _random = Random.secure();

  /// A manual pairing code may be tried this many times before the receiver
  /// rotates it. This keeps a six-digit code from being brute-forced over an
  /// open receive session.
  static const _maxFailedPairingAttempts = 5;

  final StreamController<ReceiverEndpoint> _receiverController =
      StreamController<ReceiverEndpoint>.broadcast();
  final StreamController<List<IncomingTransferRequest>>
  _incomingRequestsController =
      StreamController<List<IncomingTransferRequest>>.broadcast();

  final List<IncomingTransferRequest> _incomingRequests = [];
  final Map<String, _OutgoingSession> _outgoingSessions = {};
  final Map<String, _IncomingSession> _incomingSessions = {};
  final Map<String, _PreparedPeer> _preparedPeers = {};

  ReceiverEndpoint _receiver = const ReceiverEndpoint.idle();
  ServerSocket? _server;
  StreamSubscription<Socket>? _serverSubscription;
  Socket? _activeIncomingSocket;
  String? _receiverSessionId;
  String? _pairingCode;
  TransferInvitation? _invitation;
  Timer? _invitationTimer;
  Future<void>? _recoveryFuture;
  var _failedPairingAttempts = 0;
  bool _disposed = false;

  @override
  ReceiverEndpoint get currentReceiver => _receiver;

  @override
  Stream<ReceiverEndpoint> watchReceiver() async* {
    yield _receiver;
    yield* _receiverController.stream;
  }

  @override
  Stream<List<TransferTask>> watchTransfers() async* {
    await recoverIncompleteTransfers();
    yield* _repository.watchTransfers();
  }

  @override
  Stream<List<IncomingTransferRequest>> watchIncomingRequests() async* {
    yield List<IncomingTransferRequest>.unmodifiable(_incomingRequests);
    yield* _incomingRequestsController.stream;
  }

  @override
  Future<void> recoverIncompleteTransfers() {
    return _recoveryFuture ??= _recover();
  }

  Future<void> _recover() async {
    await _repository.failIncomplete(
      'Relay was closed before this transfer finished. '
      'It was not added to the library.',
    );
    await _deleteAllTemporaryFiles();
  }

  @override
  Future<ReceiverEndpoint> startReceiving() async {
    _ensureNotDisposed();
    await recoverIncompleteTransfers();
    if (_receiver.isListening) return _receiver;

    await _ensureTemporaryDirectory();
    final addresses = await _localIpv4Addresses();
    try {
      final server = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        _limits.preferredPort,
      );
      _server = server;
      _serverSubscription = server.listen(
        (socket) => unawaited(_handleIncoming(socket)),
        onError: (_) {
          // A single failed accept must not tear down receive mode.
        },
      );
      _receiverSessionId = _newCredential(16);
      _pairingCode = _newPairingCode();
      _invitation = addresses.isEmpty
          ? null
          : _createInvitation(port: server.port, addresses: addresses);
      _receiver = ReceiverEndpoint(
        isListening: true,
        port: server.port,
        pairingCode: _pairingCode,
        addresses: addresses,
        phase: ReceiverPhase.waiting,
        invitation: _invitation,
        message: addresses.isEmpty
            ? 'No Wi-Fi IPv4 address was found. Connect this device to the '
                  'same Wi-Fi network as the sender.'
            : null,
      );
      _scheduleInvitationExpiry();
    } catch (_) {
      _clearReceiverSession();
      _receiver = const ReceiverEndpoint(
        isListening: false,
        phase: ReceiverPhase.idle,
        message:
            'Relay could not start receive mode. Another app may be using '
            'the port, or the network is unavailable.',
      );
    }
    _emitReceiver();
    return _receiver;
  }

  @override
  Future<ReceiverEndpoint> refreshInvitation() async {
    _ensureNotDisposed();
    if (!_receiver.isListening || _receiver.phase != ReceiverPhase.waiting) {
      throw const TransferRequestException(
        'A new code can only be created while receive mode is waiting.',
      );
    }
    if (!_receiver.hasWifiAddress) {
      throw const TransferRequestException(
        'Connect this device to Wi-Fi before creating a QR code.',
      );
    }
    _rotateInvitation(statusMessage: 'A new one-time code is ready.');
    return _receiver;
  }

  @override
  Future<void> stopReceiving() async {
    final active = _incomingSessions.isEmpty
        ? null
        : _incomingSessions.values.first;
    if (active != null) {
      active.cancelReason = 'Receive mode was stopped.';
      active.socket.destroy();
    }
    _activeIncomingSocket?.destroy();
    _activeIncomingSocket = null;
    _invitationTimer?.cancel();
    _invitationTimer = null;
    await _serverSubscription?.cancel();
    _serverSubscription = null;
    await _server?.close();
    _server = null;
    _incomingRequests.clear();
    _emitIncomingRequests();
    _clearReceiverSession();
    if (!_disposed) {
      _receiver = const ReceiverEndpoint.idle();
      _emitReceiver();
    }
  }

  @override
  Future<void> approveIncoming(String transferId) async {
    final session = _incomingSessions[transferId];
    if (session == null || !session.waitingForApproval) {
      throw const TransferRequestException(
        'This incoming transfer is no longer waiting for approval.',
      );
    }
    session.waitingForApproval = false;
    _removeIncomingRequest(transferId);
    if (!session.approval.isCompleted) session.approval.complete(true);
  }

  @override
  Future<void> rejectIncoming(String transferId) async {
    final session = _incomingSessions[transferId];
    if (session == null || !session.waitingForApproval) {
      throw const TransferRequestException(
        'This incoming transfer is no longer waiting for approval.',
      );
    }
    session.waitingForApproval = false;
    _removeIncomingRequest(transferId);
    if (!session.approval.isCompleted) session.approval.complete(false);
  }

  @override
  Future<void> cancel(String transferId) async {
    final task = await _repository.findById(transferId);
    if (task == null) {
      throw const TransferRequestException('The transfer was not found.');
    }
    if (!task.canCancel) {
      throw const TransferRequestException(
        'This transfer can no longer be cancelled.',
      );
    }

    final outgoing = _outgoingSessions[transferId];
    if (outgoing != null) {
      outgoing.cancelReason = 'Transfer cancelled on this device.';
      outgoing.socket?.destroy();
      return;
    }

    final incoming = _incomingSessions[transferId];
    if (incoming != null) {
      incoming.cancelReason = 'Transfer cancelled on this device.';
      _removeIncomingRequest(transferId);
      incoming.socket.destroy();
      return;
    }

    await _repository.updateStatus(
      transferId,
      TransferStatus.cancelled,
      note: 'Transfer cancelled on this device.',
      clearTemporaryFile: true,
    );
  }

  @override
  Future<void> removeTransfer(String transferId) {
    return _repository.delete(transferId);
  }

  @override
  Future<void> clearCompleted() {
    return _repository.clearCompleted();
  }

  @override
  Future<ConnectedPeer> connectWithInvitation(
    TransferInvitation invitation,
  ) async {
    _ensureNotDisposed();
    await recoverIncompleteTransfers();
    if (invitation.isExpiredAt(DateTime.now())) {
      throw const TransferRequestException(
        'This QR code has expired. Ask the receiver to show a new one.',
      );
    }
    if (invitation.protocolVersion != relayProtocolVersion) {
      throw const TransferRequestException(
        'This QR code uses a different Relay transfer version. Update Relay '
        'on both devices.',
      );
    }

    Socket? socket;
    TransferConnection? connection;
    String? connectedAddress;
    for (final address in invitation.addresses) {
      try {
        socket = await Socket.connect(
          address,
          invitation.port,
          timeout: _limits.connectTimeout,
        );
        connection = TransferConnection(socket, _limits);
        connectedAddress = address;
        break;
      } on SocketException {
        socket = null;
      } on TimeoutException {
        socket = null;
      }
    }
    if (socket == null || connection == null) {
      throw const TransferRequestException(
        'Relay could not reach the receiving device. Check that both devices '
        'are on the same Wi-Fi network and that receive mode is still on.',
      );
    }

    try {
      await connection.writeMessage(
        HelloMessage(
          peerName: _deviceName,
          sessionId: invitation.sessionId,
          invitationToken: invitation.token,
        ),
      );
      final welcome = await connection.readMessage(
        timeout: _limits.handshakeTimeout,
      );
      if (welcome is ErrorMessage) {
        throw _connectFailure(welcome);
      }
      if (welcome is! WelcomeMessage) {
        throw const TransferRequestException(
          'The receiving device did not complete the Relay connection.',
        );
      }
      final peerId = _newId('peer');
      final peer = _PreparedPeer(
        id: peerId,
        connection: connection,
        socket: socket,
        deviceName: welcome.deviceName,
        address: connectedAddress ?? invitation.addresses.first,
        port: invitation.port,
      );
      _preparedPeers[peerId] = peer;
      peer.closeTimer = Timer(
        _limits.offerTimeout + const Duration(seconds: 15),
        () => unawaited(disconnectPeer(peerId)),
      );
      return ConnectedPeer(
        id: peerId,
        deviceName: welcome.deviceName,
        address: peer.address,
        port: peer.port,
      );
    } catch (error) {
      await connection.close();
      if (error is TransferRequestException) rethrow;
      if (error is _TransferFailure) {
        throw TransferRequestException(error.message);
      }
      if (error is TransferTimeoutException) {
        throw const TransferRequestException(
          'The receiving device did not answer in time. Ask them to show a '
          'new QR code and try again.',
        );
      }
      if (error is TransferConnectionClosedException) {
        throw const TransferRequestException(
          'The receiving device closed the connection. Ask them to show a new '
          'QR code and try again.',
        );
      }
      if (error is TransferProtocolException) {
        throw const TransferRequestException(
          'The receiving device sent an invalid Relay response. Update Relay '
          'on both devices.',
        );
      }
      throw const TransferRequestException(
        'Relay could not verify this receiving device. Ask them to show a new '
        'QR code and try again.',
      );
    }
  }

  @override
  Future<TransferTask> sendDocumentToPeer({
    required String documentId,
    required String peerId,
  }) async {
    _ensureNotDisposed();
    await recoverIncompleteTransfers();
    final peer = _preparedPeers.remove(peerId);
    if (peer == null) {
      throw const TransferRequestException(
        'The connection to the receiving device is no longer active. '
        'Scan its QR code again.',
      );
    }
    peer.closeTimer?.cancel();
    peer.closeTimer = null;

    final _LoadedDocument loaded;
    try {
      loaded = await _loadDocumentForSending(documentId);
    } catch (_) {
      await peer.close();
      rethrow;
    }

    final transferId = _newId('tx');
    final session = _OutgoingSession()..socket = peer.socket;
    _outgoingSessions[transferId] = session;
    try {
      await _repository.create(
        TransferDraft(
          id: transferId,
          direction: TransferDirection.send,
          documentId: loaded.document.id,
          documentTitle: loaded.document.title,
          fileTypeLabel: loaded.document.format.label,
          sizeBytes: loaded.document.sizeBytes,
          peerName: peer.deviceName,
          status: TransferStatus.connecting,
          createdAt: DateTime.now(),
        ),
      );
    } catch (_) {
      _outgoingSessions.remove(transferId);
      await peer.close();
      rethrow;
    }

    return _performOutgoingTransfer(
      transferId: transferId,
      loaded: loaded,
      session: session,
      peerLabel: peer.deviceName,
      handshake: () async => _OutgoingHandshake(
        connection: peer.connection,
        socket: peer.socket,
        deviceName: peer.deviceName,
        address: peer.address,
        port: peer.port,
      ),
    );
  }

  @override
  Future<void> disconnectPeer(String peerId) async {
    final peer = _preparedPeers.remove(peerId);
    if (peer == null) return;
    await peer.close();
  }

  @override
  Future<TransferTask> sendDocument({
    required String documentId,
    required String host,
    required int port,
    required String pairingCode,
  }) async {
    _ensureNotDisposed();
    await recoverIncompleteTransfers();

    final normalizedHost = host.trim();
    final address = InternetAddress.tryParse(normalizedHost);
    if (address == null || address.type != InternetAddressType.IPv4) {
      throw const TransferRequestException(
        'Enter the IPv4 address shown on the receiving device.',
      );
    }
    if (port < 1 || port > 65535) {
      throw const TransferRequestException('Enter a valid port number.');
    }
    final trimmedCode = pairingCode.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(trimmedCode)) {
      throw const TransferRequestException(
        'Enter the six-digit pairing code shown on the receiving device.',
      );
    }

    final loaded = await _loadDocumentForSending(documentId);
    final transferId = _newId('tx');
    final session = _OutgoingSession();
    _outgoingSessions[transferId] = session;
    try {
      await _repository.create(
        TransferDraft(
          id: transferId,
          direction: TransferDirection.send,
          documentId: loaded.document.id,
          documentTitle: loaded.document.title,
          fileTypeLabel: loaded.document.format.label,
          sizeBytes: loaded.document.sizeBytes,
          peerName: normalizedHost,
          status: TransferStatus.connecting,
          createdAt: DateTime.now(),
        ),
      );
    } catch (_) {
      _outgoingSessions.remove(transferId);
      rethrow;
    }

    return _performOutgoingTransfer(
      transferId: transferId,
      loaded: loaded,
      session: session,
      peerLabel: normalizedHost,
      handshake: () async {
        TransferConnection? connection;
        Socket? socket;
        try {
          socket = await Socket.connect(
            normalizedHost,
            port,
            timeout: _limits.connectTimeout,
          );
          session.socket = socket;
          if (session.cancelReason != null) {
            socket.destroy();
            throw _TransferCancelled(session.cancelReason!);
          }
          connection = TransferConnection(socket, _limits);
          await connection.writeMessage(
            HelloMessage(peerName: _deviceName, pairingCode: trimmedCode),
          );
          final welcome = await connection.readMessage(
            timeout: _limits.handshakeTimeout,
          );
          if (welcome is ErrorMessage) {
            throw _remoteFailure(welcome);
          }
          if (welcome is! WelcomeMessage) {
            throw const _TransferFailure(
              'The receiving device did not complete the Relay handshake.',
              code: 'invalid_handshake',
            );
          }
          return _OutgoingHandshake(
            connection: connection,
            socket: socket,
            deviceName: welcome.deviceName,
            address: normalizedHost,
            port: port,
          );
        } catch (_) {
          await connection?.close();
          socket?.destroy();
          rethrow;
        }
      },
    );
  }

  Future<_LoadedDocument> _loadDocumentForSending(String documentId) async {
    final document = await _documentRepository.findById(documentId);
    if (document == null) {
      throw const TransferRequestException('That document is not in Relay.');
    }
    if (!document.isImported ||
        document.isMissing ||
        document.storedFileName == null ||
        document.storedFileName!.isEmpty) {
      throw const TransferRequestException(
        'Relay no longer has its managed copy of this document.',
      );
    }
    if (!await _fileStore.exists(document.storedFileName!)) {
      throw const TransferRequestException(
        'Relay could not find its managed copy of this document.',
      );
    }
    if (document.sizeBytes <= 0 ||
        document.sizeBytes > _limits.maxDocumentBytes) {
      throw TransferRequestException(
        'This document is larger than the '
        '${_formatBytes(_limits.maxDocumentBytes)} transfer limit.',
      );
    }
    final checksum = document.sha256?.trim().toLowerCase() ?? '';
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(checksum)) {
      throw const TransferRequestException(
        'Relay cannot verify this document. Import it again before sending.',
      );
    }
    final manifest = TransferManifest.validated(
      fileName: _safeSenderFileName(document),
      title: _safeTitle(document.title),
      format: document.format.name,
      sizeBytes: document.sizeBytes,
      sha256: checksum,
      maxBytes: _limits.maxDocumentBytes,
    );
    return _LoadedDocument(
      document: document,
      manifest: manifest,
      file: File(_fileStore.pathFor(document.storedFileName!)),
    );
  }

  Future<TransferTask> _performOutgoingTransfer({
    required String transferId,
    required _LoadedDocument loaded,
    required _OutgoingSession session,
    required String peerLabel,
    required Future<_OutgoingHandshake> Function() handshake,
  }) async {
    TransferConnection? connection;
    var deviceName = peerLabel;
    final document = loaded.document;
    final manifest = loaded.manifest;
    try {
      if (session.cancelReason != null) {
        throw _TransferCancelled(session.cancelReason!);
      }
      final handshakeResult = await handshake();
      connection = handshakeResult.connection;
      session.socket = handshakeResult.socket;
      deviceName = handshakeResult.deviceName;
      await _repository.updatePeerName(transferId, deviceName);
      if (session.cancelReason != null) {
        throw _TransferCancelled(session.cancelReason!);
      }

      final actualLength = await loaded.file.length();
      if (actualLength != document.sizeBytes) {
        throw const _TransferFailure(
          'Relay’s managed copy no longer matches its library record. '
          'Import the document again before sending it.',
          code: 'file_changed',
        );
      }

      await connection.writeMessage(OfferMessage(manifest: manifest));
      await _repository.updateStatus(
        transferId,
        TransferStatus.awaitingApproval,
      );
      final decision = await connection.readMessage(
        timeout: _limits.approvalTimeout + _limits.handshakeTimeout,
      );
      if (decision is ErrorMessage) {
        throw _remoteFailure(decision);
      }
      if (decision is RejectMessage) {
        throw const _TransferCancelled(
          'The receiving device declined this transfer.',
        );
      }
      if (decision is CancelMessage) {
        throw const _TransferCancelled(
          'The receiving device cancelled this transfer.',
        );
      }
      if (decision is! AcceptMessage) {
        throw const _TransferFailure(
          'The receiving device did not accept the document manifest.',
          code: 'invalid_acceptance',
        );
      }

      await _repository.updateStatus(transferId, TransferStatus.transferring);
      var sentBytes = 0;
      var lastReportAt = DateTime.now();
      final digestCapture = _DigestCapture();
      final digestSink = sha256.startChunkedConversion(digestCapture);

      await for (final chunk in loaded.file.openRead()) {
        if (session.cancelReason != null) {
          throw _TransferCancelled(session.cancelReason!);
        }
        final bytes = chunk is Uint8List ? chunk : Uint8List.fromList(chunk);
        await connection.writeData(bytes, timeout: _limits.inactivityTimeout);
        digestSink.add(bytes);
        sentBytes += bytes.length;
        if (sentBytes > document.sizeBytes) {
          throw const _TransferFailure(
            'Relay’s managed copy changed while it was being sent.',
            code: 'file_changed',
          );
        }
        final now = DateTime.now();
        if (now.difference(lastReportAt) >= _limits.progressUpdateInterval &&
            sentBytes < document.sizeBytes) {
          await _repository.updateProgress(transferId, sentBytes);
          lastReportAt = now;
        }
      }
      digestSink.close();
      final actualHash = digestCapture.value?.toString() ?? '';

      if (sentBytes != document.sizeBytes ||
          actualHash.toLowerCase() != manifest.sha256) {
        throw const _TransferFailure(
          'Relay’s managed copy changed before the transfer finished. '
          'The receiving device did not receive a valid document.',
          code: 'file_changed',
        );
      }

      await _repository.updateStatus(
        transferId,
        TransferStatus.verifying,
        transferredBytes: sentBytes,
      );
      await connection.writeMessage(
        CompleteMessage(sizeBytes: sentBytes, sha256: actualHash),
      );
      final result = await connection.readMessage(
        timeout: _limits.verificationTimeout,
      );
      if (result is ErrorMessage) {
        throw _remoteFailure(result);
      }
      if (result is CancelMessage) {
        throw const _TransferCancelled(
          'The receiving device cancelled this transfer.',
        );
      }
      if (result is! CompletedMessage) {
        throw const _TransferFailure(
          'The receiving device did not confirm the completed document.',
          code: 'invalid_completion',
        );
      }

      await _repository.updateStatus(
        transferId,
        TransferStatus.completed,
        transferredBytes: sentBytes,
        documentId: document.id,
        note: result.duplicate
            ? 'The receiving device already had this document.'
            : 'Delivered to $deviceName.',
      );
    } on _TransferCancelled catch (error) {
      await _markOutgoingCancelled(transferId, error.reason);
      if (connection != null) {
        await _trySend(
          connection,
          CancelMessage(reason: 'Transfer cancelled by the sender.'),
        );
      }
    } on _TransferFailure catch (error) {
      await _markOutgoingFailed(transferId, error.message);
      if (connection != null) {
        await _trySend(
          connection,
          ErrorMessage(code: error.code, message: error.message),
        );
      }
    } on TransferValidationException catch (error) {
      await _markOutgoingFailed(transferId, error.message);
      if (connection != null) {
        await _trySend(
          connection,
          ErrorMessage(code: error.code, message: error.message),
        );
      }
    } on TransferProtocolException catch (error) {
      await _markOutgoingFailed(transferId, error.message);
      if (connection != null) {
        await _trySend(
          connection,
          ErrorMessage(code: error.code, message: error.message),
        );
      }
    } on TransferTimeoutException catch (error) {
      await _markOutgoingFailed(transferId, error.message);
      if (connection != null) {
        await _trySend(
          connection,
          const ErrorMessage(
            code: 'timeout',
            message: 'The transfer timed out.',
          ),
        );
      }
    } on TransferConnectionClosedException {
      await _markOutgoingFailed(
        transferId,
        'The connection to the receiving device was lost. '
        'The document was not delivered.',
      );
    } on SocketException {
      await _markOutgoingFailed(
        transferId,
        'Relay could not reach the receiving device. Check that both devices '
        'are on the same Wi-Fi network and that the address, port and code are '
        'correct.',
      );
    } on TimeoutException {
      await _markOutgoingFailed(
        transferId,
        'The connection timed out. Check the receiving device is still in '
        'receive mode and both devices are on the same Wi-Fi network.',
      );
    } on FileSystemException {
      await _markOutgoingFailed(
        transferId,
        'Relay could not read its managed copy of this document.',
      );
    } catch (_) {
      await _markOutgoingFailed(
        transferId,
        'The transfer stopped unexpectedly. The document was not delivered.',
      );
    } finally {
      _outgoingSessions.remove(transferId);
      await connection?.close();
    }

    return (await _repository.findById(transferId)) ??
        TransferTask(
          id: transferId,
          documentId: document.id,
          documentTitle: document.title,
          fileTypeLabel: document.format.label,
          sizeBytes: document.sizeBytes,
          direction: TransferDirection.send,
          deviceName: deviceName,
          status: TransferStatus.failed,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          failureReason: 'The transfer record could not be read.',
        );
  }

  Future<void> _handleIncoming(Socket socket) async {
    if (_activeIncomingSocket != null) {
      final connection = TransferConnection(socket, _limits);
      await _trySend(
        connection,
        const ErrorMessage(
          code: 'busy',
          message: 'This device is already receiving another document.',
        ),
      );
      await connection.close();
      return;
    }
    _activeIncomingSocket = socket;
    TransferConnection? connection;
    _IncomingSession? session;
    IOSink? sink;
    var invitationConsumed = false;
    String? resultMessage;
    try {
      connection = TransferConnection(socket, _limits);
      final hello = await connection.readMessage(
        timeout: _limits.handshakeTimeout,
      );
      if (hello is! HelloMessage) {
        throw const _TransferFailure(
          'The sender did not start a Relay transfer.',
          code: 'invalid_handshake',
        );
      }

      if (hello.usesInvitation) {
        final now = DateTime.now();
        if (hello.sessionId != _receiverSessionId) {
          throw const _TransferFailure(
            'This QR code is not for this receiving session.',
            code: 'invitation_invalid',
          );
        }
        final invitation = _invitation;
        if (invitation == null) {
          throw const _TransferFailure(
            'This QR code has already been used. Ask the receiver to show a '
            'new one.',
            code: 'invitation_used',
          );
        }
        if (invitation.token != hello.invitationToken) {
          throw const _TransferFailure(
            'This QR code has already been used or replaced. Ask the receiver '
            'to show a new one.',
            code: 'invitation_used',
          );
        }
        if (invitation.isExpiredAt(now)) {
          _rotateInvitation(
            statusMessage: 'The previous code expired. A new code is ready.',
          );
          throw const _TransferFailure(
            'This QR code has expired. Ask the receiver to show a new one.',
            code: 'invitation_expired',
          );
        }
      } else {
        final pairingCode = hello.pairingCode;
        if (_pairingCode == null ||
            pairingCode == null ||
            pairingCode != _pairingCode) {
          _failedPairingAttempts++;
          final locked = _failedPairingAttempts >= _maxFailedPairingAttempts;
          if (locked) {
            _failedPairingAttempts = 0;
            _rotateInvitation(
              statusMessage:
                  'Too many incorrect pairing codes. A new code is ready.',
            );
          }
          throw _TransferFailure(
            locked
                ? 'Too many incorrect pairing attempts. Ask the receiving '
                      'device to show its new code.'
                : 'The sender used an incorrect or expired pairing code.',
            code: locked ? 'pairing_locked' : 'pairing_code',
          );
        }
      }

      _failedPairingAttempts = 0;

      invitationConsumed = true;
      _invitationTimer?.cancel();
      _invitationTimer = null;
      _invitation = null;
      _pairingCode = null;
      _setReceiverPhase(
        ReceiverPhase.connected,
        peerName: hello.peerName,
        documentTitle: null,
        statusMessage: null,
      );
      await connection.writeMessage(WelcomeMessage(deviceName: _deviceName));

      final offer = await connection.readMessage(timeout: _limits.offerTimeout);
      if (offer is! OfferMessage) {
        throw const _TransferFailure(
          'The sender did not provide a document manifest.',
          code: 'invalid_offer',
        );
      }
      final manifest = offer.manifest;
      final transferId = _newId('rx');
      final tempFileName = '$transferId.part';
      final now = DateTime.now();
      await _repository.create(
        TransferDraft(
          id: transferId,
          direction: TransferDirection.receive,
          documentTitle: manifest.title,
          fileTypeLabel: manifest.format.label,
          sizeBytes: manifest.sizeBytes,
          peerName: hello.peerName,
          status: TransferStatus.awaitingApproval,
          createdAt: now,
          tempFileName: tempFileName,
        ),
      );

      session = _IncomingSession(
        id: transferId,
        manifest: manifest,
        peerName: hello.peerName,
        tempFileName: tempFileName,
        connection: connection,
        socket: socket,
      );
      _incomingSessions[transferId] = session;
      _setReceiverPhase(
        ReceiverPhase.awaitingApproval,
        peerName: hello.peerName,
        documentTitle: manifest.title,
        statusMessage: null,
      );
      _addIncomingRequest(
        IncomingTransferRequest(
          transferId: transferId,
          manifest: manifest,
          peerName: hello.peerName,
        ),
      );

      final outcome = await _waitForApproval(session);
      _removeIncomingRequest(transferId);
      session.waitingForApproval = false;

      if (session.cancelReason != null) {
        throw _TransferCancelled(session.cancelReason!);
      }
      if (outcome == _ApprovalOutcome.rejected) {
        resultMessage = 'You declined “${manifest.title}”.';
        await _markIncomingCancelled(transferId, 'You declined this transfer.');
        await _trySend(
          connection,
          const RejectMessage(reason: 'The receiving device declined it.'),
        );
        return;
      }
      if (outcome == _ApprovalOutcome.disconnected) {
        throw const _TransferFailure(
          'The sender disconnected before this document was approved.',
          code: 'disconnected',
        );
      }
      if (outcome == _ApprovalOutcome.timedOut) {
        throw const _TransferFailure(
          'This incoming transfer was not approved in time.',
          code: 'approval_timeout',
        );
      }

      await _repository.updateStatus(transferId, TransferStatus.transferring);
      _setReceiverPhase(
        ReceiverPhase.transferring,
        peerName: hello.peerName,
        documentTitle: manifest.title,
        statusMessage: null,
      );
      await connection.writeMessage(const AcceptMessage());

      final tempFile = _temporaryFile(session.tempFileName);
      sink = tempFile.openWrite();
      final digestCapture = _DigestCapture();
      final digestSink = sha256.startChunkedConversion(digestCapture);
      var receivedBytes = 0;
      var flushedBytes = 0;
      var lastReportAt = DateTime.now();
      try {
        await connection.readData(
          manifest.sizeBytes,
          onChunk: (chunk) async {
            if (session!.cancelReason != null) {
              throw _TransferCancelled(session.cancelReason!);
            }
            sink!.add(chunk);
            digestSink.add(chunk);
            receivedBytes += chunk.length;

            // Bound the IOSink buffer for large documents by periodically
            // waiting for the disk writer to drain.
            if (receivedBytes - flushedBytes >= 512 * 1024) {
              await sink.flush();
              flushedBytes = receivedBytes;
            }

            final now = DateTime.now();
            if (now.difference(lastReportAt) >=
                    _limits.progressUpdateInterval &&
                receivedBytes < manifest.sizeBytes) {
              await _repository.updateProgress(transferId, receivedBytes);
              lastReportAt = now;
            }
          },
        );
        await sink.flush();
        await sink.close();
        sink = null;
        digestSink.close();
      } on FileSystemException catch (error) {
        throw _TransferFailure(_storageFailureMessage(error), code: 'storage');
      }
      final actualHash = digestCapture.value?.toString() ?? '';
      await _repository.updateStatus(
        transferId,
        TransferStatus.verifying,
        transferredBytes: receivedBytes,
      );

      final completed = await connection.readMessage(
        timeout: _limits.verificationTimeout,
      );
      if (completed is ErrorMessage) {
        throw _remoteFailure(completed);
      }
      if (completed is CancelMessage) {
        throw const _TransferCancelled('The sender cancelled this transfer.');
      }
      if (completed is! CompleteMessage) {
        throw const _TransferFailure(
          'The sender did not finish the transfer correctly.',
          code: 'invalid_completion',
        );
      }
      if (completed.sizeBytes != manifest.sizeBytes ||
          completed.sizeBytes != receivedBytes ||
          actualHash.toLowerCase() != manifest.sha256 ||
          completed.sha256 != manifest.sha256) {
        throw const _TransferFailure(
          'The received file did not match its declared size and checksum. '
          'It was not added to the library.',
          code: 'checksum_mismatch',
        );
      }
      final length = await tempFile.length();
      if (length != manifest.sizeBytes) {
        throw const _TransferFailure(
          'The received file was incomplete and was not added to the library.',
          code: 'size_mismatch',
        );
      }

      final result = await _incomingHandler.importVerifiedFile(
        temporaryPath: tempFile.path,
        manifest: manifest,
        peerName: session.peerName,
      );
      final imported = switch (result.outcome) {
        ImportOutcome.success => result.document,
        ImportOutcome.duplicate => result.existingDocument,
        ImportOutcome.failure => null,
      };
      if (imported == null) {
        throw _TransferFailure(
          result.message ??
              'Relay could not add the received document to the library.',
          code: 'import_failed',
        );
      }

      await _repository.updateStatus(
        transferId,
        TransferStatus.completed,
        transferredBytes: manifest.sizeBytes,
        documentId: imported.id,
        note: result.outcome == ImportOutcome.duplicate
            ? 'Already in your library as “${imported.title}”.'
            : 'Added to your library as “${imported.title}”.',
        clearTemporaryFile: true,
      );
      resultMessage = result.outcome == ImportOutcome.duplicate
          ? 'Verified “${imported.title}”. It was already in your library.'
          : 'Received “${imported.title}” from ${session.peerName}.';
      await _trySend(
        connection,
        CompletedMessage(
          duplicate: result.outcome == ImportOutcome.duplicate,
          documentTitle: imported.title,
        ),
      );
    } on _TransferCancelled catch (error) {
      resultMessage ??=
          'The incoming transfer was cancelled. '
          'Nothing was added to the library.';
      if (session != null) {
        await _markIncomingCancelled(session.id, error.reason);
        await _trySend(
          connection,
          CancelMessage(reason: 'The receiving device cancelled the transfer.'),
        );
      }
    } on _TransferFailure catch (error) {
      resultMessage ??=
          'The last transfer did not complete. Nothing was added to the '
          'library.';
      if (session != null) {
        await _markIncomingError(session, error.message);
      }
      await _trySend(
        connection,
        ErrorMessage(code: error.code, message: error.message),
      );
    } on TransferValidationException catch (error) {
      resultMessage ??=
          'The last transfer did not complete. Nothing was added to the '
          'library.';
      if (session != null) {
        await _markIncomingError(session, error.message);
      }
      await _trySend(
        connection,
        ErrorMessage(code: error.code, message: error.message),
      );
    } on TransferProtocolException catch (error) {
      resultMessage ??=
          'The last transfer did not complete. Nothing was added to the '
          'library.';
      if (session != null) {
        await _markIncomingError(session, error.message);
      }
      await _trySend(
        connection,
        ErrorMessage(code: error.code, message: error.message),
      );
    } on TransferTimeoutException catch (error) {
      resultMessage ??=
          'The last transfer did not complete. Nothing was added to the '
          'library.';
      if (session != null) {
        await _markIncomingError(session, error.message);
      }
      await _trySend(
        connection,
        const ErrorMessage(code: 'timeout', message: 'The transfer timed out.'),
      );
    } on TransferConnectionClosedException {
      resultMessage ??=
          'The last transfer did not complete. Nothing was added to the '
          'library.';
      if (session != null) {
        await _markIncomingError(
          session,
          'The connection was lost before the document was complete. '
          'Nothing was added to the library.',
        );
      }
    } on FileSystemException catch (error) {
      resultMessage ??=
          'The last transfer did not complete. Nothing was added to the '
          'library.';
      final message = _storageFailureMessage(error);
      if (session != null) {
        await _markIncomingError(session, message);
      }
      await _trySend(
        connection,
        ErrorMessage(code: 'storage', message: message),
      );
    } catch (_) {
      const message =
          'The incoming transfer stopped unexpectedly. '
          'Nothing was added to the library.';
      resultMessage ??= message;
      if (session != null) {
        await _markIncomingError(session, message);
      }
      await _trySend(
        connection,
        const ErrorMessage(code: 'transfer_failed', message: message),
      );
    } finally {
      // Close the file writer before deleting the partial file. On Windows an
      // open handle prevents deletion.
      try {
        await sink?.close();
      } catch (_) {
        // The connection failure that brought us here may also have broken
        // the sink; cleanup still has to run.
      }
      if (session != null) {
        _removeIncomingRequest(session.id);
        await _deleteTemporaryFile(session.tempFileName);
        _incomingSessions.remove(session.id);
      }
      await connection?.close();
      if (identical(_activeIncomingSocket, socket)) {
        _activeIncomingSocket = null;
      }
      if (!_disposed &&
          _receiver.isListening &&
          (invitationConsumed || session != null)) {
        _rotateInvitation(
          statusMessage:
              resultMessage ?? 'A new one-time code is ready to receive.',
        );
      }
    }
  }

  Future<_ApprovalOutcome> _waitForApproval(_IncomingSession session) async {
    final outcome =
        await Future.any<_ApprovalOutcome>([
          session.approval.future.then(
            (accepted) => accepted
                ? _ApprovalOutcome.accepted
                : _ApprovalOutcome.rejected,
          ),
          session.socket.done.then((_) => _ApprovalOutcome.disconnected),
        ]).timeout(
          _limits.approvalTimeout,
          onTimeout: () => _ApprovalOutcome.timedOut,
        );
    if (session.cancelReason != null) {
      return _ApprovalOutcome.disconnected;
    }
    return outcome;
  }

  Future<void> _markOutgoingCancelled(String id, String reason) async {
    await _markTerminal(id, TransferStatus.cancelled, note: reason);
  }

  Future<void> _markOutgoingFailed(String id, String reason) async {
    await _markTerminal(id, TransferStatus.failed, failureReason: reason);
  }

  Future<void> _markIncomingCancelled(String id, String reason) async {
    await _markTerminal(id, TransferStatus.cancelled, note: reason);
  }

  Future<void> _markIncomingFailed(String id, String reason) async {
    await _markTerminal(id, TransferStatus.failed, failureReason: reason);
  }

  Future<void> _markIncomingError(
    _IncomingSession session,
    String message,
  ) async {
    if (session.cancelReason != null) {
      await _markIncomingCancelled(session.id, session.cancelReason!);
    } else {
      await _markIncomingFailed(session.id, message);
    }
  }

  Future<void> _markTerminal(
    String id,
    TransferStatus status, {
    String? note,
    String? failureReason,
  }) async {
    try {
      final task = await _repository.findById(id);
      if (task == null || task.isTerminal) return;
      await _repository.updateStatus(
        id,
        status,
        note: note,
        failureReason: failureReason,
        clearTemporaryFile: true,
      );
    } catch (_) {
      // Preserve the original transfer error. The record remains inspectable.
    }
  }

  _TransferFailure _remoteFailure(ErrorMessage error) {
    final message = switch (error.code) {
      'pairing_code' => 'The receiving device rejected the pairing code.',
      'pairing_locked' =>
        'Too many incorrect pairing attempts. Ask the receiving device for '
            'its new code.',
      'unsupported_version' =>
        'The receiving device does not support this Relay transfer version.',
      'file_too_large' =>
        'The receiving device refused the document because it is too large.',
      'busy' => 'The receiving device is already receiving another document.',
      'approval_timeout' =>
        'The receiving device did not approve the transfer in time.',
      'checksum_mismatch' =>
        'The receiving device could not verify the file checksum.',
      'storage' => 'The receiving device does not have enough free storage.',
      'timeout' => 'The connection timed out during the transfer.',
      _ => 'The receiving device could not accept this transfer.',
    };
    return _TransferFailure(message, code: error.code);
  }

  Future<void> _trySend(
    TransferConnection? connection,
    WireMessage message,
  ) async {
    if (connection == null || connection.isClosed) return;
    try {
      await connection.writeMessage(message);
    } catch (_) {
      // Communication is best effort after a failure or cancellation.
    }
  }

  void _addIncomingRequest(IncomingTransferRequest request) {
    _incomingRequests
      ..removeWhere((item) => item.transferId == request.transferId)
      ..add(request);
    _emitIncomingRequests();
  }

  void _removeIncomingRequest(String transferId) {
    final before = _incomingRequests.length;
    _incomingRequests.removeWhere((item) => item.transferId == transferId);
    if (before != _incomingRequests.length) _emitIncomingRequests();
  }

  void _emitIncomingRequests() {
    if (_disposed || _incomingRequestsController.isClosed) return;
    _incomingRequestsController.add(
      List<IncomingTransferRequest>.unmodifiable(_incomingRequests),
    );
  }

  void _emitReceiver() {
    if (_disposed || _receiverController.isClosed) return;
    _receiverController.add(_receiver);
  }

  TransferInvitation _createInvitation({
    required int port,
    required List<String> addresses,
  }) {
    final sessionId = _receiverSessionId;
    if (sessionId == null) {
      throw const TransferRequestException(
        'Relay has no active receive session.',
      );
    }
    return TransferInvitation.validated(
      sessionId: sessionId,
      token: _newCredential(32),
      addresses: addresses,
      port: port,
      expiresAt: DateTime.now().toUtc().add(_limits.invitationTtl),
    );
  }

  void _clearReceiverSession() {
    _invitationTimer?.cancel();
    _invitationTimer = null;
    _receiverSessionId = null;
    _pairingCode = null;
    _invitation = null;
    _failedPairingAttempts = 0;
  }

  void _scheduleInvitationExpiry() {
    _invitationTimer?.cancel();
    final invitation = _invitation;
    if (invitation == null) {
      _invitationTimer = null;
      return;
    }
    final delay =
        invitation.remainingAt(DateTime.now()) +
        const Duration(milliseconds: 25);
    _invitationTimer = Timer(delay, () {
      if (_disposed ||
          !_receiver.isListening ||
          _receiver.phase != ReceiverPhase.waiting) {
        return;
      }
      _rotateInvitation(
        statusMessage: 'The previous code expired. A new code is ready.',
      );
    });
  }

  void _rotateInvitation({String? statusMessage}) {
    if (!_receiver.isListening || _receiver.port == null) return;
    _failedPairingAttempts = 0;
    _receiverSessionId ??= _newCredential(16);
    _pairingCode = _newPairingCode();
    _invitation = _receiver.addresses.isEmpty
        ? null
        : _createInvitation(
            port: _receiver.port!,
            addresses: _receiver.addresses,
          );
    _receiver = ReceiverEndpoint(
      isListening: true,
      port: _receiver.port,
      pairingCode: _pairingCode,
      addresses: _receiver.addresses,
      message: _receiver.message,
      phase: ReceiverPhase.waiting,
      invitation: _invitation,
      peerName: null,
      documentTitle: null,
      statusMessage: statusMessage,
    );
    _scheduleInvitationExpiry();
    _emitReceiver();
  }

  void _setReceiverPhase(
    ReceiverPhase phase, {
    String? peerName,
    String? documentTitle,
    String? statusMessage,
  }) {
    if (!_receiver.isListening) return;
    _receiver = ReceiverEndpoint(
      isListening: true,
      port: _receiver.port,
      pairingCode: null,
      addresses: _receiver.addresses,
      message: _receiver.message,
      phase: phase,
      invitation: null,
      peerName: peerName,
      documentTitle: documentTitle,
      statusMessage: statusMessage,
    );
    _emitReceiver();
  }

  TransferRequestException _connectFailure(ErrorMessage error) {
    final message = switch (error.code) {
      'invitation_used' =>
        'This QR code has already been used. Ask the receiver to show a new '
            'one.',
      'invitation_expired' =>
        'This QR code has expired. Ask the receiver to show a new one.',
      'invitation_invalid' =>
        'This QR code is not valid for the receiving session. Ask the '
            'receiver to show a new one.',
      'pairing_code' =>
        'The receiving device rejected the pairing code or it has expired.',
      'pairing_locked' =>
        'Too many incorrect codes. Ask the receiving device for its new '
            'pairing code.',
      'unsupported_version' =>
        'The receiving device does not support this Relay transfer version.',
      'busy' => 'The receiving device is already connected to another sender.',
      _ => _remoteFailure(error).message,
    };
    return TransferRequestException(message);
  }

  Future<List<String>> _localIpv4Addresses() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      final addresses = <String>{};
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (address.isLoopback || address.address.startsWith('169.254.')) {
            continue;
          }
          addresses.add(address.address);
        }
      }
      final sorted = addresses.toList()..sort();
      return sorted;
    } catch (_) {
      return const <String>[];
    }
  }

  Future<void> _ensureTemporaryDirectory() async {
    if (!await _temporaryDirectory.exists()) {
      await _temporaryDirectory.create(recursive: true);
    }
  }

  File _temporaryFile(String fileName) {
    if (p.basename(fileName) != fileName ||
        fileName.contains('..') ||
        fileName.isEmpty) {
      throw const _TransferFailure(
        'Relay refused an unsafe temporary file name.',
        code: 'invalid_temp_file',
      );
    }
    return File(p.join(_temporaryDirectory.path, fileName));
  }

  Future<void> _deleteTemporaryFile(String fileName) async {
    try {
      final file = _temporaryFile(fileName);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // The next startup sweep removes abandoned transfer files.
    }
  }

  Future<void> _deleteAllTemporaryFiles() async {
    try {
      if (!await _temporaryDirectory.exists()) return;
      await for (final entity in _temporaryDirectory.list()) {
        try {
          await entity.delete(recursive: true);
        } catch (_) {
          // Best effort. No library file lives in this directory.
        }
      }
    } catch (_) {
      // The transfer directory is optional until receive mode starts.
    }
  }

  String _newPairingCode() {
    return (100000 + _random.nextInt(900000)).toString();
  }

  String _newCredential(int byteLength) {
    final bytes = List<int>.generate(
      byteLength,
      (_) => _random.nextInt(256),
      growable: false,
    );
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  String _newId(String prefix) {
    final buffer = StringBuffer('$prefix-');
    for (var i = 0; i < 12; i++) {
      buffer.write(_random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  static String _safeSenderFileName(Document document) {
    var name = (document.fileName ?? '').trim();
    if (name.isEmpty) {
      name = '${document.title}.${document.format.fileExtension}';
    }
    name = name
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
        .replaceAll(RegExp(r'[\\/]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final expected = '.${document.format.fileExtension}';
    if (p.extension(name).toLowerCase() != expected) {
      name = '${p.basenameWithoutExtension(name)}$expected';
    }
    if (name.isEmpty || name == expected) {
      name = 'document$expected';
    }
    if (name.length > 180) {
      final extension = p.extension(name);
      name = name.substring(0, 180 - extension.length) + extension;
    }
    return name;
  }

  static String _safeTitle(String title) {
    final clean = title
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (clean.isEmpty) return 'Untitled document';
    return clean.length <= 200 ? clean : clean.substring(0, 200);
  }

  static String _safePeerName(String name) {
    final clean = name
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (clean.isEmpty) return 'Relay device';
    return clean.length <= 80 ? clean : clean.substring(0, 80);
  }

  static String _storageFailureMessage(FileSystemException error) {
    final details = '${error.message} ${error.osError?.message ?? ''}'
        .toLowerCase();
    if (details.contains('no space') || error.osError?.errorCode == 28) {
      return 'There is not enough free storage on this device. '
          'The received document was not added to the library.';
    }
    return 'Relay could not write the incoming document. '
        'The transfer was not added to the library.';
  }

  static String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).round()} MB';
    }
    return '${(bytes / 1024).round()} KB';
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw const TransferRequestException(
        'The transfer service is no longer available.',
      );
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _invitationTimer?.cancel();
    _invitationTimer = null;
    for (final session in _incomingSessions.values) {
      session.socket.destroy();
    }
    for (final session in _outgoingSessions.values) {
      session.socket?.destroy();
    }
    for (final peer in _preparedPeers.values) {
      unawaited(peer.close());
    }
    _preparedPeers.clear();
    _serverSubscription?.cancel();
    _server?.close();
    _receiverController.close();
    _incomingRequestsController.close();
  }
}
