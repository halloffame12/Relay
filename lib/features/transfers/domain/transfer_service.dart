import '../../library/domain/document.dart';
import 'transfer_invitation.dart';
import 'transfer_manifest.dart';
import 'transfer_task.dart';

class TransferRequestException implements Exception {
  const TransferRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The visible state of the foreground receive session. A session can be open
/// while a sender is connected but before a document has been offered.
enum ReceiverPhase { idle, waiting, connected, awaitingApproval, transferring }

class ConnectedPeer {
  const ConnectedPeer({
    required this.id,
    required this.deviceName,
    required this.address,
    required this.port,
  });

  final String id;
  final String deviceName;
  final String address;
  final int port;
}

class ReceiverEndpoint {
  const ReceiverEndpoint({
    required this.isListening,
    this.port,
    this.pairingCode,
    this.addresses = const <String>[],
    this.message,
    ReceiverPhase? phase,
    this.invitation,
    this.peerName,
    this.documentTitle,
    this.statusMessage,
  }) : phase =
           phase ?? (isListening ? ReceiverPhase.waiting : ReceiverPhase.idle);

  const ReceiverEndpoint.idle()
    : this(
        isListening: false,
        phase: ReceiverPhase.idle,
        message: 'Receive mode is off.',
      );

  final bool isListening;
  final int? port;
  final String? pairingCode;
  final List<String> addresses;

  /// A warning about the environment, such as no usable Wi-Fi address. It is
  /// not the result of the last transfer.
  final String? message;
  final ReceiverPhase phase;

  /// Non-null only while the session is waiting and the code has not been
  /// consumed. The QR widget must never be shown for a connected phase.
  final TransferInvitation? invitation;
  final String? peerName;
  final String? documentTitle;

  /// A short, non-sensitive result notice shown after a connection ends.
  final String? statusMessage;

  String? get primaryAddress => addresses.isEmpty ? null : addresses.first;

  String? get addressLabel {
    final address = primaryAddress;
    final boundPort = port;
    if (address == null || boundPort == null) return null;
    return '$address:$boundPort';
  }

  bool get hasWifiAddress => addresses.isNotEmpty;

  bool get isWaiting =>
      isListening && phase == ReceiverPhase.waiting && invitation != null;

  bool get isConnected =>
      isListening &&
      (phase == ReceiverPhase.connected ||
          phase == ReceiverPhase.awaitingApproval ||
          phase == ReceiverPhase.transferring);
}

class IncomingTransferRequest {
  const IncomingTransferRequest({
    required this.transferId,
    required this.manifest,
    required this.peerName,
  });

  final String transferId;
  final TransferManifest manifest;
  final String peerName;

  DocumentFormat get format => manifest.format;
  int get sizeBytes => manifest.sizeBytes;
  String get title => manifest.title;
}

abstract interface class TransferService {
  ReceiverEndpoint get currentReceiver;

  Stream<ReceiverEndpoint> watchReceiver();

  Stream<List<TransferTask>> watchTransfers();

  Stream<List<IncomingTransferRequest>> watchIncomingRequests();

  Future<ReceiverEndpoint> startReceiving();

  Future<void> stopReceiving();

  /// Generates a new single-use token and manual code for the active receive
  /// session without restarting the server.
  Future<ReceiverEndpoint> refreshInvitation();

  /// Validates an invitation, connects to the receiver, and holds the verified
  /// connection open while the sender chooses a document.
  Future<ConnectedPeer> connectWithInvitation(TransferInvitation invitation);

  /// Sends a managed document over a connection returned by
  /// [connectWithInvitation]. The receiver still has to approve the transfer.
  Future<TransferTask> sendDocumentToPeer({
    required String documentId,
    required String peerId,
  });

  /// Closes a prepared connection when the sender leaves without sending.
  Future<void> disconnectPeer(String peerId);

  Future<TransferTask> sendDocument({
    required String documentId,
    required String host,
    required int port,
    required String pairingCode,
  });

  Future<void> approveIncoming(String transferId);

  Future<void> rejectIncoming(String transferId);

  Future<void> cancel(String transferId);

  Future<void> removeTransfer(String transferId);

  Future<void> clearCompleted();

  Future<void> recoverIncompleteTransfers();

  void dispose();
}
