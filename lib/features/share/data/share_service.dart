import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../../core/utils/untrusted_text.dart';
import '../../import/domain/document_import_service.dart';
import '../../library/domain/document.dart';
import '../../library/domain/document_file_store.dart';
import '../../library/domain/document_repository.dart';
import '../../transfers/data/incoming_transfer_handler.dart';
import '../../transfers/domain/transfer_limits.dart';
import '../../transfers/domain/transfer_manifest.dart';
import '../domain/share_frame.dart';
import '../domain/share_invitation.dart';
import '../domain/share_offer.dart';
import '../domain/share_protocol.dart';
import '../domain/share_state.dart';
import 'share_link.dart';
import 'signaling_client.dart';
import 'webrtc_share_link.dart';

class ShareException implements Exception {
  const ShareException(this.message, {this.code = 'share'});

  final String message;
  final String code;

  @override
  String toString() => message;
}

/// Creates the cross-network link. Injectable so the LAN path and the session
/// protocol can be exercised without a real TURN deployment.
abstract interface class WebRtcConnector {
  Future<ShareLink> connectSender({
    required ShareInvitation invitation,
    required String deviceName,
    required Duration timeout,
  });

  Future<ShareLink> connectReceiver({
    required ShareInvitation invitation,
    required String deviceName,
    required Duration timeout,
  });
}

/// Default connector: signaling room plus WebRTC data channel. The signaling
/// service supplies short-lived ICE (including TURN) credentials per session.
class SignalingWebRtcConnector implements WebRtcConnector {
  SignalingWebRtcConnector({
    required this.url,
    this.negotiationTimeout = const Duration(seconds: 25),
  });

  final String url;
  final Duration negotiationTimeout;

  Uri get _baseUrl {
    final uri = Uri.tryParse(url);
    if (uri == null || (!uri.isScheme('wss') && !uri.isScheme('ws'))) {
      throw const ShareException(
        'Cross-network sharing is not configured in this build.',
        code: 'signaling_not_configured',
      );
    }
    return uri;
  }

  @override
  Future<ShareLink> connectSender({
    required ShareInvitation invitation,
    required String deviceName,
    required Duration timeout,
  }) async {
    final signaling = SignalingClient(
      baseUrl: _baseUrl,
      sessionId: invitation.sessionId,
      token: invitation.token,
      role: 'sender',
      deviceName: deviceName,
      connectTimeout: timeout,
    );
    try {
      final ice = await signaling.connect();
      final deadline = DateTime.now().add(negotiationTimeout);
      while (true) {
        final event = await signaling.next(
          timeout: _remaining(deadline, negotiationTimeout),
        );
        if (event is SignalingPeerJoined) break;
      }
      final link = await WebRtcNegotiator.connectSender(
        signaling: signaling,
        ice: ice,
        timeout: _remaining(deadline, negotiationTimeout),
      );
      return _SignalBoundLink(link, signaling);
    } catch (_) {
      await signaling.close();
      rethrow;
    }
  }

  @override
  Future<ShareLink> connectReceiver({
    required ShareInvitation invitation,
    required String deviceName,
    required Duration timeout,
  }) async {
    final signaling = SignalingClient(
      baseUrl: _baseUrl,
      sessionId: invitation.sessionId,
      token: invitation.token,
      role: 'receiver',
      deviceName: deviceName,
      connectTimeout: timeout,
    );
    try {
      final ice = await signaling.connect();
      final link = await WebRtcNegotiator.connectReceiver(
        signaling: signaling,
        ice: ice,
        timeout: negotiationTimeout,
      );
      return _SignalBoundLink(link, signaling);
    } catch (_) {
      await signaling.close();
      rethrow;
    }
  }

  static Duration _remaining(DateTime deadline, Duration fallback) {
    final remaining = deadline.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      throw const ShareException(
        'The connection attempt timed out.',
        code: 'timeout',
      );
    }
    return remaining < fallback ? remaining : fallback;
  }
}

/// Closes the signaling socket together with the data channel. Once the data
/// channel is open, no further signaling messages are required.
class _SignalBoundLink implements ShareLink {
  _SignalBoundLink(this._inner, this._signaling);

  final ShareLink _inner;
  final SignalingClient _signaling;

  @override
  SharePath get path => _inner.path;

  @override
  bool get isOpen => _inner.isOpen;

  @override
  Stream<Uint8List> get incoming => _inner.incoming;

  @override
  int get bufferedAmount => _inner.bufferedAmount;

  @override
  int get preferredChunkBytes => _inner.preferredChunkBytes;

  @override
  void add(Uint8List bytes) => _inner.add(bytes);

  @override
  Future<void> drain() => _inner.drain();

  @override
  Future<void> close() async {
    await _inner.close();
    await _signaling.close();
  }
}

class _OutgoingDocument {
  const _OutgoingDocument({
    required this.document,
    required this.manifest,
    required this.file,
  });

  final Document document;
  final TransferManifest manifest;
  final File file;
}

class _SessionCancelled implements Exception {
  const _SessionCancelled();
}

/// Orchestrates sender-initiated share sessions.
///
/// The sender shows a QR code. The receiver scans it, connects over the local
/// network when possible and otherwise over a WebRTC data channel, then
/// explicitly approves the file list before any bytes are written.
class ShareService {
  ShareService({
    required DocumentRepository documentRepository,
    required DocumentFileStore fileStore,
    required IncomingTransferHandler incomingHandler,
    required Directory temporaryDirectory,
    required String deviceName,
    required TransferLimits limits,
    String? signalingUrl,
    WebRtcConnector? webRtcConnector,
    Future<int?> Function(Directory directory)? freeSpaceProbe,
    Future<List<String>> Function()? localAddressResolver,
    InternetAddress? bindAddress,
  }) : _documentRepository = documentRepository,
       _fileStore = fileStore,
       _incomingHandler = incomingHandler,
       _temporaryDirectory = temporaryDirectory,
       _deviceName = deviceName,
       _limits = limits,
       _bindAddress = bindAddress ?? InternetAddress.anyIPv4,
       _freeSpaceProbe = freeSpaceProbe,
       _localAddressResolver = localAddressResolver ?? _defaultLocalAddresses,
       _webRtcConnector =
           webRtcConnector ?? _connectorFor(signalingUrl ?? relaySignalingUrl);

  /// Returns a signaling-backed connector only when an operator has supplied a
  /// signaling endpoint. Without one, Relay stays on the LAN path and the UI
  /// says so instead of pretending cross-network sharing is available.
  static WebRtcConnector? _connectorFor(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;
    return SignalingWebRtcConnector(url: trimmed);
  }

  final DocumentRepository _documentRepository;
  final DocumentFileStore _fileStore;
  final IncomingTransferHandler _incomingHandler;
  final Directory _temporaryDirectory;
  final String _deviceName;
  final TransferLimits _limits;
  final InternetAddress _bindAddress;
  final Future<int?> Function(Directory directory)? _freeSpaceProbe;
  final Future<List<String>> Function() _localAddressResolver;
  final WebRtcConnector? _webRtcConnector;

  final Random _random = Random.secure();
  final StreamController<SenderShareState> _senderController =
      StreamController<SenderShareState>.broadcast();
  final StreamController<ReceiverShareState> _receiverController =
      StreamController<ReceiverShareState>.broadcast();

  SenderShareState _sender = const SenderShareState.idle();
  ReceiverShareState _receiver = const ReceiverShareState.idle();

  ServerSocket? _server;
  StreamSubscription<Socket>? _serverSubscription;
  ShareLink? _senderLink;
  ShareInbox? _senderInbox;
  ShareInvitation? _invitation;
  String? _sessionId;
  String? _token;
  bool _tokenConsumed = false;
  bool _senderRunning = false;
  bool _senderCancelRequested = false;
  Timer? _expiryTimer;
  DateTime? _transferStartedAt;
  DateTime _lastProgressEmit = DateTime.fromMillisecondsSinceEpoch(0);
  List<_OutgoingDocument> _outgoing = const <_OutgoingDocument>[];

  ShareLink? _receiverLink;
  ShareInbox? _receiverInbox;
  Completer<bool>? _approval;
  bool _receiverRunning = false;
  bool _receiverCancelRequested = false;
  String? _receiverSessionId;
  bool _disposed = false;

  SenderShareState get sender => _sender;

  ReceiverShareState get receiver => _receiver;

  bool get isCrossNetworkConfigured => _webRtcConnector != null;

  Stream<SenderShareState> watchSender() async* {
    yield _sender;
    yield* _senderController.stream;
  }

  Stream<ReceiverShareState> watchReceiver() async* {
    yield _receiver;
    yield* _receiverController.stream;
  }

  // ---------------------------------------------------------------------------
  // Sender
  // ---------------------------------------------------------------------------

  /// Loads the selected managed documents and opens a short-lived share session.
  Future<void> startSender(List<String> documentIds) async {
    _ensureNotDisposed();
    if (documentIds.isEmpty) {
      throw const ShareException('Choose at least one document to send.');
    }
    if (_senderRunning) {
      throw const ShareException('A share is already in progress.');
    }
    await _resetSender();
    _senderRunning = true;
    _senderCancelRequested = false;
    _setSender(
      const SenderShareState(
        phase: SharePhase.preparing,
        message: 'Preparing your documents…',
      ),
    );

    try {
      final outgoing = <_OutgoingDocument>[];
      for (final id in documentIds) {
        outgoing.add(await _loadDocument(id));
      }
      final totalBytes = outgoing.fold<int>(
        0,
        (sum, item) => sum + item.manifest.sizeBytes,
      );
      if (outgoing.length > shareMaxFilesPerBatch) {
        throw ShareException(
          'Relay can send up to $shareMaxFilesPerBatch files at once.',
          code: 'too_many_files',
        );
      }
      if (totalBytes > shareMaxBatchBytes) {
        throw const ShareException(
          'That selection is larger than the Relay transfer limit.',
          code: 'batch_too_large',
        );
      }

      _outgoing = outgoing;
      _sessionId = _newCredential(16);
      _token = _newCredential(32);
      _tokenConsumed = false;

      _server = await ServerSocket.bind(_bindAddress, 0);
      _serverSubscription = _server!.listen(
        _onIncomingSenderSocket,
        onError: (_) {},
      );

      final addresses = await _localAddressResolver();
      final endpoints = <ShareEndpoint>[
        for (final address in addresses.take(shareMaxLanEndpoints))
          ShareEndpoint(host: address, port: _server!.port),
      ];
      _invitation = ShareInvitation.create(
        sessionId: _sessionId!,
        token: _token!,
        expiresAt: DateTime.now().toUtc().add(_limits.invitationTtl),
        lanEndpoints: endpoints,
        senderName: _deviceName,
      );

      _setSender(
        SenderShareState(
          phase: SharePhase.waiting,
          invitation: _invitation,
          fileCount: outgoing.length,
          totalBytes: totalBytes,
          progress: ShareProgress(
            totalBytes: totalBytes,
            fileCount: outgoing.length,
          ),
        ),
      );
      _scheduleExpiry();

      // The signaling room is opened in parallel. A failure here does not break
      // the LAN path; the sender UI simply explains that only nearby devices
      // can connect.
      unawaited(_startSignaling());
    } on ShareException catch (error) {
      await _failSender(error.message);
      rethrow;
    } catch (error) {
      await _failSender(_friendlySenderError(error));
      rethrow;
    }
  }

  Future<void> refreshSenderInvitation() async {
    _ensureNotDisposed();
    if (_sender.phase != SharePhase.waiting) return;
    await _closeSenderServer();
    await _resetTransport();
    await _openSenderSession(keepPrepared: true);
  }

  Future<void> stopSender() async {
    if (!_senderRunning) {
      await _resetSender();
      return;
    }
    _senderCancelRequested = true;
    await _resetSender();
    _setSender(const SenderShareState.idle());
  }

  Future<void> cancelSender() async {
    _senderCancelRequested = true;
    final link = _senderLink;
    if (link != null) {
      try {
        link.add(
          ShareFrameCodec.encode(
            const CancelShareMessage(reason: 'The sender cancelled.').toFrame(),
          ),
        );
        await link.drain();
      } catch (_) {
        // The connection may already be gone.
      }
    }
    await _resetSender();
    _setSender(
      const SenderShareState(
        phase: SharePhase.cancelled,
        message: 'You cancelled this share.',
      ),
    );
  }

  Future<void> _openSenderSession({required bool keepPrepared}) async {
    _sessionId = _newCredential(16);
    _token = _newCredential(32);
    _tokenConsumed = false;
    if (_server == null) {
      _server = await ServerSocket.bind(_bindAddress, 0);
      _serverSubscription = _server!.listen(
        _onIncomingSenderSocket,
        onError: (_) {},
      );
    }
    final addresses = await _localAddressResolver();
    _invitation = ShareInvitation.create(
      sessionId: _sessionId!,
      token: _token!,
      expiresAt: DateTime.now().toUtc().add(_limits.invitationTtl),
      lanEndpoints: <ShareEndpoint>[
        for (final address in addresses.take(shareMaxLanEndpoints))
          ShareEndpoint(host: address, port: _server!.port),
      ],
      senderName: _deviceName,
    );
    _setSender(
      SenderShareState(
        phase: SharePhase.waiting,
        invitation: _invitation,
        fileCount: keepPrepared ? _sender.fileCount : 0,
        totalBytes: keepPrepared ? _sender.totalBytes : 0,
        progress: _sender.progress,
      ),
    );
    _scheduleExpiry();
    unawaited(_startSignaling());
  }

  Future<void> _startSignaling() async {
    final connector = _webRtcConnector;
    final invitation = _invitation;
    if (connector == null || invitation == null) return;
    try {
      final link = await connector.connectSender(
        invitation: invitation,
        deviceName: _deviceName,
        timeout: _limits.connectTimeout,
      );
      if (_sender.phase != SharePhase.waiting || _tokenConsumed) {
        await link.close();
        return;
      }
      await _acceptSenderLink(link);
    } catch (_) {
      // LAN remains available. Do not surface a second error on top of the
      // active session; the waiting UI already explains the nearby-only case.
    }
  }

  void _onIncomingSenderSocket(Socket socket) {
    if (_senderCancelRequested || _sender.phase != SharePhase.waiting) {
      socket.destroy();
      return;
    }
    final link = TcpShareLink(socket);
    unawaited(_acceptSenderLink(link));
  }

  Future<void> _acceptSenderLink(ShareLink link) async {
    // Reserve the session synchronously, before the first await, so a LAN
    // socket and a signaling connection cannot both be accepted.
    if (_senderLink != null || _tokenConsumed) {
      await link.close();
      return;
    }
    _tokenConsumed = true;
    _expiryTimer?.cancel();
    _senderLink = link;
    final inbox = ShareInbox(link);
    _senderInbox = inbox;
    try {
      final hello = ShareMessage.decode(
        (await inbox.nextControl(timeout: _limits.handshakeTimeout)).value,
      );
      if (hello is! HelloMessage ||
          hello.role != ShareRole.receiver ||
          !_secureEquals(hello.sessionId, _sessionId ?? '') ||
          !_secureEquals(hello.token, _token ?? '')) {
        throw const ShareException(
          'This device did not present a valid Relay session. Show a new code '
          'and try again.',
          code: 'invalid_credentials',
        );
      }
      final peer = _safePeerName(hello.deviceName);
      _setSender(
        _sender.copyWith(
          phase: SharePhase.connecting,
          clearInvitation: true,
          peerName: peer,
          path: link.path,
          clearMessage: true,
          message: 'Connected over ${link.path.label}.',
        ),
      );

      _write(link, WelcomeMessage(deviceName: _deviceName));
      await link.drain();

      final offer = ShareOffer.validated(
        batchId: _newCredential(9),
        files: [for (final item in _outgoing) item.manifest],
      );
      _write(link, OfferMessage(offer: offer));
      await link.drain();

      _setSender(
        _sender.copyWith(
          phase: SharePhase.awaitingApproval,
          message:
              'Waiting for $peer to approve ${offer.fileCount == 1 ? 'the file' : 'the files'}…',
        ),
      );

      final decision = ShareMessage.decode(
        (await inbox.nextControl(timeout: _limits.approvalTimeout)).value,
      );
      if (decision is RejectMessage) {
        await _finishSender(
          SharePhase.cancelled,
          message: '$peer declined this transfer.',
        );
        return;
      }
      if (decision is! AcceptMessage) {
        throw const ShareException(
          'The receiving device sent an unexpected response.',
          code: 'unexpected_message',
        );
      }

      await _sendFiles(link, inbox, offer);
    } on _SessionCancelled {
      await _finishSender(
        SharePhase.cancelled,
        message: 'You cancelled this share.',
      );
    } on ShareLinkException catch (error) {
      await _finishSender(
        SharePhase.failed,
        message: _friendlyLinkError(error),
      );
    } on ShareException catch (error) {
      await _finishSender(SharePhase.failed, message: error.message);
    } catch (error) {
      await _finishSender(
        SharePhase.failed,
        message: _friendlySenderError(error),
      );
    } finally {
      await inbox.dispose();
      _senderInbox = null;
      await link.close();
      _senderLink = null;
    }
  }

  Future<void> _sendFiles(
    ShareLink link,
    ShareInbox inbox,
    ShareOffer offer,
  ) async {
    _transferStartedAt = DateTime.now();
    _lastProgressEmit = DateTime.fromMillisecondsSinceEpoch(0);
    var transferred = 0;
    final results = <ShareFileResult>[];

    for (var index = 0; index < _outgoing.length; index++) {
      if (_senderCancelRequested) throw const _SessionCancelled();
      final item = _outgoing[index];
      _write(link, FileStartMessage(index: index));
      await link.drain();

      await for (final chunk in item.file.openRead()) {
        if (_senderCancelRequested) throw const _SessionCancelled();
        final bytes = chunk is Uint8List ? chunk : Uint8List.fromList(chunk);
        var offset = 0;
        while (offset < bytes.length) {
          final end = min(offset + link.preferredChunkBytes, bytes.length);
          final slice = Uint8List.sublistView(bytes, offset, end);
          link.add(ShareFrameCodec.encode(ShareDataFrame(slice)));
          offset = end;
          transferred += slice.length;
          _emitSenderProgress(
            transferred: transferred,
            total: offer.totalBytes,
            fileIndex: index,
            fileCount: offer.fileCount,
            currentFile: item.manifest.fileName,
          );
          await link.drain();
        }
      }

      _write(link, FileEndMessage(index: index));
      await link.drain();

      final response = ShareMessage.decode(
        (await inbox.nextControl(timeout: _limits.verificationTimeout)).value,
      );
      if (response is FileResultMessage && response.index == index) {
        results.add(
          ShareFileResult(
            fileName: item.manifest.fileName,
            status: resultStatusFor(response.outcome),
            message: response.message,
          ),
        );
      } else if (response is ShareErrorMessage) {
        throw ShareException(response.message, code: response.code);
      } else {
        throw const ShareException(
          'The receiving device did not confirm the file.',
          code: 'unexpected_message',
        );
      }
      _setSender(_sender.copyWith(results: List<ShareFileResult>.of(results)));
    }

    final imported = results
        .where((result) => result.status == ShareResultStatus.imported)
        .length;
    final duplicates = results
        .where((result) => result.status == ShareResultStatus.duplicate)
        .length;
    final failed = results
        .where((result) => result.status == ShareResultStatus.failed)
        .length;

    // Tells the receiver the batch is finished so it can commit the session
    // state instead of waiting for a frame that will never arrive.
    _write(
      link,
      BatchCompleteMessage(imported: imported, duplicates: duplicates),
    );
    await link.drain();

    final message = switch ((imported, duplicates, failed)) {
      (0, 0, _) => 'The receiving device could not import these files.',
      (1, 0, 0) => 'Delivered to ${_sender.peerName ?? 'the other device'}.',
      (_, _, 0) when duplicates == results.length =>
        'The receiving device already had ${results.length == 1 ? 'this file' : 'these files'}.',
      _ =>
        'Finished: $imported imported, $duplicates already there, $failed failed.',
    };

    await _finishSender(
      failed > 0 && imported == 0 && duplicates == 0
          ? SharePhase.failed
          : SharePhase.completed,
      message: message,
    );
  }

  // ---------------------------------------------------------------------------
  // Receiver
  // ---------------------------------------------------------------------------

  /// Validates a scanned code, selects a transport, and obtains the file offer.
  Future<void> join(ShareInvitation invitation) async {
    _ensureNotDisposed();
    if (_receiverRunning) {
      throw const ShareException('A receive session is already in progress.');
    }
    if (invitation.isExpiredAt(DateTime.now())) {
      throw const ShareException(
        'That code has expired. Ask the sender to show a new one.',
        code: 'expired_invitation',
      );
    }
    _receiverRunning = true;
    _receiverCancelRequested = false;
    _receiverSessionId = invitation.sessionId;
    _setReceiver(
      ReceiverShareState(
        phase: SharePhase.connecting,
        senderName: invitation.senderName,
        message: 'Connecting to ${invitation.senderName}…',
      ),
    );

    ShareLink? link;
    try {
      link = await _connectLan(invitation);
      if (link != null) {
        _setReceiver(
          _receiver.copyWith(
            path: SharePath.localWifi,
            message: 'Connected over Local Wi-Fi.',
          ),
        );
      } else {
        final connector = _webRtcConnector;
        if (connector == null) {
          throw const ShareException(
            'Relay could not reach the sender on this Wi-Fi network. Move both '
            'devices to the same network, or use a build with cross-network '
            'sharing configured.',
            code: 'no_cross_network',
          );
        }
        _setReceiver(
          _receiver.copyWith(message: 'Finding a route to the sender…'),
        );
        link = await connector.connectReceiver(
          invitation: invitation,
          deviceName: _deviceName,
          timeout: _limits.connectTimeout,
        );
        _setReceiver(
          _receiver.copyWith(
            path: link.path,
            message: 'Connected over ${link.path.label}.',
          ),
        );
      }

      _receiverLink = link;
      final inbox = ShareInbox(link);
      _receiverInbox = inbox;

      _write(
        link,
        HelloMessage(
          role: ShareRole.receiver,
          sessionId: invitation.sessionId,
          token: invitation.token,
          deviceName: _deviceName,
        ),
      );
      await link.drain();

      final welcome = ShareMessage.decode(
        (await inbox.nextControl(timeout: _limits.handshakeTimeout)).value,
      );
      if (welcome is! WelcomeMessage) {
        throw const ShareException(
          'The sending device did not accept this code.',
          code: 'invalid_credentials',
        );
      }
      final senderName = _safePeerName(welcome.deviceName);

      final offerFrame = ShareMessage.decode(
        (await inbox.nextControl(timeout: _limits.handshakeTimeout)).value,
      );
      if (offerFrame is! OfferMessage) {
        throw const ShareException(
          'The sending device did not offer any files.',
          code: 'invalid_offer',
        );
      }
      final offer = offerFrame.offer;

      await _ensureTemporaryDirectory();
      final available = await _availableBytes();
      if (available != null && available < (offer.totalBytes * 1.15)) {
        await _rejectWith(
          link,
          'There is not enough free space on the receiving device.',
        );
        await _finishReceiver(
          SharePhase.failed,
          message:
              'Not enough free space for ${_formatBytes(offer.totalBytes)}. '
              'Free some space and ask the sender for a new code.',
        );
        return;
      }

      _setReceiver(
        ReceiverShareState(
          phase: SharePhase.awaitingApproval,
          senderName: senderName,
          offer: offer,
          path: link.path,
          progress: ShareProgress(
            totalBytes: offer.totalBytes,
            fileCount: offer.fileCount,
          ),
          message: 'Review the files before receiving anything.',
        ),
      );
      final approval = Completer<bool>();
      _approval = approval;
      final approved = await approval.future.timeout(
        _limits.approvalTimeout,
        onTimeout: () => false,
      );
      if (!approved || _receiverCancelRequested) {
        await _rejectWith(
          link,
          approved
              ? 'The receive session was closed.'
              : 'The receiving device did not approve the transfer.',
        );
        await _finishReceiver(
          SharePhase.cancelled,
          message: 'You declined this transfer.',
        );
        return;
      }

      _write(link, const AcceptMessage());
      await link.drain();
      await _receiveFiles(link, inbox, offer, senderName);
    } on TimeoutException {
      await _finishReceiver(
        SharePhase.failed,
        message: 'The other device did not respond in time.',
      );
    } on _SessionCancelled {
      await _finishReceiver(
        SharePhase.cancelled,
        message: 'You cancelled this transfer.',
      );
    } on ShareLinkException catch (error) {
      await _finishReceiver(
        SharePhase.failed,
        message: _friendlyLinkError(error),
      );
    } on ShareException catch (error) {
      await _finishReceiver(SharePhase.failed, message: error.message);
    } on SignalingException catch (error) {
      await _finishReceiver(SharePhase.failed, message: error.message);
    } catch (error) {
      await _finishReceiver(
        SharePhase.failed,
        message: 'The transfer could not be completed.',
      );
    } finally {
      await _receiverInbox?.dispose();
      _receiverInbox = null;
      await _receiverLink?.close();
      _receiverLink = null;
      _receiverRunning = false;
    }
  }

  Future<ShareLink?> _connectLan(ShareInvitation invitation) async {
    for (final endpoint in invitation.lanEndpoints) {
      if (_receiverCancelRequested) return null;
      try {
        final socket = await Socket.connect(
          endpoint.host,
          endpoint.port,
          timeout: const Duration(seconds: 3),
        );
        return TcpShareLink(socket);
      } on SocketException {
        continue;
      } on TimeoutException {
        continue;
      }
    }
    return null;
  }

  Future<void> approveIncoming() async {
    final approval = _approval;
    if (approval == null || approval.isCompleted) {
      throw const ShareException('There is no transfer waiting for approval.');
    }
    approval.complete(true);
  }

  Future<void> rejectIncoming() async {
    final approval = _approval;
    if (approval == null || approval.isCompleted) return;
    _receiverCancelRequested = true;
    approval.complete(false);
  }

  Future<void> disconnectReceiver() async {
    _receiverCancelRequested = true;
    await _receiverLink?.close();
  }

  /// Clears a finished receive session so the next scan starts clean. Refuses
  /// while a transfer is still running so the UI cannot orphan an active link.
  Future<void> resetReceiver() async {
    if (_receiverRunning) {
      throw const ShareException('A receive session is still in progress.');
    }
    _approval = null;
    _receiverSessionId = null;
    _setReceiver(const ReceiverShareState.idle());
  }

  /// Clears a finished send session and releases its socket.
  Future<void> resetSender() async {
    if (_sender.phase == SharePhase.waiting ||
        _sender.phase == SharePhase.connecting ||
        _sender.phase == SharePhase.awaitingApproval ||
        _sender.phase == SharePhase.transferring) {
      await stopSender();
      return;
    }
    await _resetSender();
    _setSender(const SenderShareState.idle());
  }

  Future<void> _receiveFiles(
    ShareLink link,
    ShareInbox inbox,
    ShareOffer offer,
    String senderName,
  ) async {
    await _ensureTemporaryDirectory();
    _transferStartedAt = DateTime.now();
    _lastProgressEmit = DateTime.fromMillisecondsSinceEpoch(0);
    var transferred = 0;
    final results = <ShareFileResult>[];
    var imported = 0;
    var duplicates = 0;

    File? currentFile;
    IOSink? sink;
    TransferManifest? currentManifest;
    var fileBytes = 0;

    Future<void> finishCurrentFile() async {
      final file = currentFile;
      final manifest = currentManifest;
      if (file == null || manifest == null) {
        throw const ShareException('The sender broke the transfer sequence.');
      }
      await sink?.flush();
      await sink?.close();
      sink = null;
      if (fileBytes != manifest.sizeBytes) {
        await _safeDelete(file);
        throw const ShareException(
          'The received file was incomplete. Nothing was added.',
          code: 'incomplete_file',
        );
      }
      final digest = await sha256.bind(file.openRead()).first;
      if (digest.toString() != manifest.sha256) {
        await _safeDelete(file);
        throw const ShareException(
          'The received file did not match its checksum. Nothing was added.',
          code: 'checksum_mismatch',
        );
      }
      final result = await _incomingHandler.importVerifiedFile(
        temporaryPath: file.path,
        manifest: manifest,
        peerName: senderName,
        transportLabel: link.path.label,
      );
      await _safeDelete(file);
      final status = switch (result.outcome) {
        ImportOutcome.success => ShareResultStatus.imported,
        ImportOutcome.duplicate => ShareResultStatus.duplicate,
        ImportOutcome.failure => ShareResultStatus.failed,
      };
      if (status == ShareResultStatus.imported) imported++;
      if (status == ShareResultStatus.duplicate) duplicates++;
      results.add(
        ShareFileResult(
          fileName: manifest.fileName,
          status: status,
          message: result.message,
        ),
      );
      _write(
        link,
        FileResultMessage(
          index: offer.files.indexOf(manifest),
          outcome: outcomeFor(status),
          message: result.message,
        ),
      );
      await link.drain();
      _setReceiver(
        _receiver.copyWith(results: List<ShareFileResult>.of(results)),
      );
      currentFile = null;
      currentManifest = null;
      fileBytes = 0;
    }

    try {
      while (true) {
        if (_receiverCancelRequested) throw const _SessionCancelled();
        final frame = await inbox.next(timeout: _limits.inactivityTimeout);
        switch (frame) {
          case ShareControlFrame(:final value):
            final message = ShareMessage.decode(value);
            switch (message) {
              case FileStartMessage(:final index):
                if (sink != null) {
                  throw const ShareException(
                    'The sender started a new file before finishing the last.',
                    code: 'protocol',
                  );
                }
                if (index < 0 || index >= offer.files.length) {
                  throw const ShareException(
                    'The sender referenced an unknown file.',
                    code: 'protocol',
                  );
                }
                currentManifest = offer.files[index];
                currentFile = _temporaryFile(
                  'share-$_receiverSessionId-$index.part',
                );
                if (await currentFile!.exists()) await currentFile!.delete();
                sink = currentFile!.openWrite();
                fileBytes = 0;
              case FileEndMessage(:final index):
                if (currentManifest == null) {
                  throw const ShareException(
                    'The sender ended a file that never started.',
                    code: 'protocol',
                  );
                }
                final expectedIndex = offer.files.indexOf(currentManifest!);
                if (index != expectedIndex) {
                  throw const ShareException(
                    'The sender finished the wrong file.',
                    code: 'protocol',
                  );
                }
                await finishCurrentFile();
              case BatchCompleteMessage():
                if (sink != null) {
                  throw const ShareException(
                    'The sender ended the batch mid-file.',
                    code: 'protocol',
                  );
                }
                await _finishReceiver(
                  SharePhase.completed,
                  message: _batchMessage(imported, duplicates, results.length),
                );
                return;
              case CancelShareMessage(:final reason):
                throw ShareException(reason, code: 'remote_cancel');
              case ShareErrorMessage(:final message):
                throw ShareException(message, code: 'remote_error');
              case AcceptMessage() ||
                  RejectMessage() ||
                  HelloMessage() ||
                  WelcomeMessage() ||
                  OfferMessage() ||
                  FileResultMessage():
                throw const ShareException(
                  'The sender sent an unexpected message.',
                  code: 'protocol',
                );
            }
          case ShareDataFrame(:final bytes):
            if (sink == null || currentManifest == null) {
              throw const ShareException(
                'The sender sent file data before starting a file.',
                code: 'protocol',
              );
            }
            fileBytes += bytes.length;
            if (fileBytes > currentManifest!.sizeBytes) {
              throw const ShareException(
                'The sender sent more data than declared. Nothing was added.',
                code: 'size_mismatch',
              );
            }
            sink!.add(bytes);
            transferred += bytes.length;
            _emitReceiverProgress(
              transferred: transferred,
              total: offer.totalBytes,
              fileIndex: offer.files.indexOf(currentManifest!),
              fileCount: offer.fileCount,
              currentFile: currentManifest!.fileName,
            );
        }
      }
    } finally {
      try {
        await sink?.close();
      } catch (_) {
        // The original failure is more useful.
      }
      final file = currentFile;
      if (file != null) await _safeDelete(file);
    }
  }

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  Future<void> _resetSender() async {
    _senderCancelRequested = true;
    _expiryTimer?.cancel();
    _expiryTimer = null;
    await _serverSubscription?.cancel();
    _serverSubscription = null;
    await _server?.close();
    _server = null;
    await _resetTransport();
    _outgoing = const <_OutgoingDocument>[];
    _senderRunning = false;
    _transferStartedAt = null;
  }

  Future<void> _resetTransport() async {
    await _senderInbox?.dispose();
    _senderInbox = null;
    await _senderLink?.close();
    _senderLink = null;
    _tokenConsumed = false;
  }

  Future<void> _closeSenderServer() async {
    await _serverSubscription?.cancel();
    _serverSubscription = null;
    await _server?.close();
    _server = null;
  }

  Future<void> _failSender(String message) async {
    await _resetSender();
    _setSender(SenderShareState(phase: SharePhase.failed, message: message));
  }

  Future<void> _finishSender(
    SharePhase phase, {
    required String message,
  }) async {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    await _closeSenderServer();
    _senderRunning = false;
    _setSender(_sender.copyWith(phase: phase, message: message));
  }

  Future<void> _finishReceiver(
    SharePhase phase, {
    required String message,
  }) async {
    _receiverRunning = false;
    _setReceiver(_receiver.copyWith(phase: phase, message: message));
  }

  Future<void> _rejectWith(ShareLink link, String reason) async {
    try {
      _write(link, RejectMessage(reason: reason));
      await link.drain();
    } catch (_) {
      // The peer may already be gone.
    }
  }

  void _write(ShareLink link, ShareMessage message) {
    link.add(ShareFrameCodec.encode(message.toFrame()));
  }

  void _scheduleExpiry() {
    _expiryTimer?.cancel();
    final invitation = _invitation;
    if (invitation == null) return;
    final delay = invitation.remainingAt(DateTime.now());
    _expiryTimer = Timer(delay, () async {
      if (_sender.phase != SharePhase.waiting) return;
      await _closeSenderServer();
      _senderRunning = false;
      _setSender(
        const SenderShareState(
          phase: SharePhase.failed,
          message: 'This code expired. Create a new one to keep sharing.',
        ),
      );
    });
  }

  Future<_OutgoingDocument> _loadDocument(String id) async {
    final document = await _documentRepository.findById(id);
    if (document == null) {
      throw const ShareException('That document is no longer in your library.');
    }
    if (!document.isAvailableOffline || document.storedFileName == null) {
      throw ShareException(
        '“${document.title}” is not stored on this device.',
        code: 'missing_file',
      );
    }
    final checksum = document.sha256?.trim().toLowerCase() ?? '';
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(checksum)) {
      throw ShareException(
        'Relay cannot verify “${document.title}”. Import it again before '
        'sending.',
        code: 'invalid_checksum',
      );
    }
    final file = File(_fileStore.pathFor(document.storedFileName!));
    if (!await file.exists()) {
      throw ShareException(
        'The stored copy of “${document.title}” is missing.',
        code: 'missing_file',
      );
    }
    final length = await file.length();
    if (length != document.sizeBytes) {
      throw ShareException(
        '“${document.title}” changed on this device. Import it again before '
        'sending.',
        code: 'file_changed',
      );
    }

    return _OutgoingDocument(
      document: document,
      manifest: TransferManifest.validated(
        fileName: _safeFileName(document),
        title: UntrustedText.clean(
          document.title,
          maxLength: UntrustedText.maxTitleLength,
        ),
        format: document.format.name,
        sizeBytes: document.sizeBytes,
        sha256: checksum,
        maxBytes: _limits.maxDocumentBytes,
      ),
      file: file,
    );
  }

  static String _safeFileName(Document document) {
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
      name = 'relay-document$expected';
    }
    return name.length <= 180 ? name : name.substring(name.length - 180);
  }

  static String _safePeerName(String name) {
    final clean = UntrustedText.clean(name, maxLength: 80);
    return clean.isEmpty ? 'Relay device' : clean;
  }

  Future<void> _ensureTemporaryDirectory() async {
    if (!await _temporaryDirectory.exists()) {
      await _temporaryDirectory.create(recursive: true);
    }
  }

  File _temporaryFile(String name) {
    if (p.basename(name) != name || name.contains('..') || name.isEmpty) {
      throw const ShareException(
        'Relay refused an unsafe temporary file name.',
      );
    }
    return File(p.join(_temporaryDirectory.path, name));
  }

  Future<void> _safeDelete(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Temporary files are swept on the next share.
    }
  }

  Future<int?> _availableBytes() async {
    if (_freeSpaceProbe != null) {
      try {
        return await _freeSpaceProbe(_temporaryDirectory);
      } catch (_) {
        return null;
      }
    }
    try {
      final result = await Process.run('df', [
        '-k',
        _temporaryDirectory.path,
      ]).timeout(const Duration(seconds: 2));
      if (result.exitCode != 0) return null;
      final lines = (result.stdout as String)
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();
      if (lines.length < 2) return null;
      final fields = lines.last.trim().split(RegExp(r'\s+'));
      if (fields.length < 4) return null;
      final availableKb = int.tryParse(fields[3]);
      return availableKb == null ? null : availableKb * 1024;
    } catch (_) {
      return null;
    }
  }

  void _emitSenderProgress({
    required int transferred,
    required int total,
    required int fileIndex,
    required int fileCount,
    required String currentFile,
  }) {
    final now = DateTime.now();
    if (now.difference(_lastProgressEmit) < const Duration(milliseconds: 120) &&
        transferred < total) {
      return;
    }
    _lastProgressEmit = now;
    final started = _transferStartedAt;
    final seconds = started == null
        ? 0.0
        : now.difference(started).inMilliseconds / 1000;
    final speed = seconds > 0.25 ? transferred / seconds : 0.0;
    final remainingBytes = total - transferred;
    _setSender(
      _sender.copyWith(
        phase: SharePhase.transferring,
        progress: ShareProgress(
          transferredBytes: transferred,
          totalBytes: total,
          fileIndex: fileIndex,
          fileCount: fileCount,
          currentFile: currentFile,
          bytesPerSecond: speed,
          remaining: speed > 1024
              ? Duration(seconds: (remainingBytes / speed).round())
              : null,
        ),
        clearMessage: true,
        message: fileCount > 1
            ? 'Sending file ${fileIndex + 1} of $fileCount…'
            : 'Sending ${_formatBytes(total)}…',
      ),
    );
  }

  void _emitReceiverProgress({
    required int transferred,
    required int total,
    required int fileIndex,
    required int fileCount,
    required String currentFile,
  }) {
    final now = DateTime.now();
    if (now.difference(_lastProgressEmit) < const Duration(milliseconds: 120) &&
        transferred < total) {
      return;
    }
    _lastProgressEmit = now;
    final started = _transferStartedAt;
    final seconds = started == null
        ? 0.0
        : now.difference(started).inMilliseconds / 1000;
    final speed = seconds > 0.25 ? transferred / seconds : 0.0;
    final remainingBytes = total - transferred;
    _setReceiver(
      _receiver.copyWith(
        phase: SharePhase.transferring,
        progress: ShareProgress(
          transferredBytes: transferred,
          totalBytes: total,
          fileIndex: fileIndex,
          fileCount: fileCount,
          currentFile: currentFile,
          bytesPerSecond: speed,
          remaining: speed > 1024
              ? Duration(seconds: (remainingBytes / speed).round())
              : null,
        ),
        message: fileCount > 1
            ? 'Receiving file ${fileIndex + 1} of $fileCount…'
            : 'Receiving ${_formatBytes(total)}…',
      ),
    );
  }

  void _setSender(SenderShareState state) {
    _sender = state;
    if (!_senderController.isClosed) _senderController.add(state);
  }

  void _setReceiver(ReceiverShareState state) {
    _receiver = state;
    if (!_receiverController.isClosed) _receiverController.add(state);
  }

  String _newCredential(int bytes) {
    final value = List<int>.generate(bytes, (_) => _random.nextInt(256));
    return base64Url.encode(value).replaceAll('=', '');
  }

  static bool _secureEquals(String a, String b) {
    if (a.length != b.length || a.isEmpty) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  static String _friendlyLinkError(ShareLinkException error) {
    return switch (error.code) {
      'timeout' =>
        'The connection stalled. Check that both devices are still open and '
            'try again.',
      'closed' => 'The other device closed the connection before finishing.',
      'webrtc_failed' =>
        'The cross-network connection failed. Try again, or move both devices '
            'to a less restrictive network.',
      'webrtc_timeout' =>
        'The cross-network connection took too long. Try again.',
      _ => error.message,
    };
  }

  static String _friendlySenderError(Object error) {
    if (error is ShareException) return error.message;
    if (error is ShareLinkException) return _friendlyLinkError(error);
    if (error is SocketException) {
      return 'Relay could not open a local connection on this device.';
    }
    return 'Relay could not start this share. Try again.';
  }

  static String _batchMessage(int imported, int duplicates, int total) {
    if (imported == total) {
      return total == 1
          ? 'Received 1 file. It’s in your library.'
          : 'Received $total files. They’re in your library.';
    }
    if (duplicates == total) {
      return total == 1
          ? 'That file was already in your library.'
          : 'All $total files were already in your library.';
    }
    return 'Finished: $imported imported, $duplicates already there.';
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static Future<List<String>> _defaultLocalAddresses() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      final addresses = <String>{};
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (address.isLoopback ||
              address.address.startsWith('169.254.') ||
              address.address.startsWith('127.')) {
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

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('ShareService was disposed.');
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _senderCancelRequested = true;
    _receiverCancelRequested = true;
    _expiryTimer?.cancel();
    _expiryTimer = null;
    await _receiverInbox?.dispose();
    await _receiverLink?.close();
    await _resetSender();
    await _senderController.close();
    await _receiverController.close();
  }
}
