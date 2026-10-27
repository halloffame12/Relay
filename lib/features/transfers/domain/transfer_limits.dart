/// Bounds and timeouts for direct LAN transfers.
///
/// These are deliberately centralised so every socket, file, and protocol
/// boundary uses the same limits. Tests inject smaller values where needed.
class TransferLimits {
  const TransferLimits({
    this.maxDocumentBytes = 100 * 1024 * 1024,
    this.maxControlMessageBytes = 64 * 1024,
    this.connectTimeout = const Duration(seconds: 12),
    this.handshakeTimeout = const Duration(seconds: 12),
    this.offerTimeout = const Duration(minutes: 2),
    this.approvalTimeout = const Duration(minutes: 2),
    this.verificationTimeout = const Duration(minutes: 2),
    this.inactivityTimeout = const Duration(seconds: 20),
    this.progressUpdateInterval = const Duration(milliseconds: 220),
    this.invitationTtl = const Duration(minutes: 5),
    this.preferredPort = 0,
  });

  /// Matches the local import limit. Only one copy is kept in Relay.
  final int maxDocumentBytes;

  /// A control message is one newline-terminated UTF-8 JSON object. It is
  /// intentionally much larger than any valid manifest but still bounded.
  final int maxControlMessageBytes;

  final Duration connectTimeout;
  final Duration handshakeTimeout;

  /// Time the receiver keeps a verified connection open while the sender
  /// chooses a library document.
  final Duration offerTimeout;
  final Duration approvalTimeout;
  final Duration verificationTimeout;
  final Duration inactivityTimeout;
  final Duration progressUpdateInterval;

  /// Lifetime of a QR invitation and its manual pairing code.
  final Duration invitationTtl;
  final int preferredPort;

  TransferLimits copyWith({
    int? maxDocumentBytes,
    int? maxControlMessageBytes,
    Duration? connectTimeout,
    Duration? handshakeTimeout,
    Duration? offerTimeout,
    Duration? approvalTimeout,
    Duration? verificationTimeout,
    Duration? inactivityTimeout,
    Duration? progressUpdateInterval,
    Duration? invitationTtl,
    int? preferredPort,
  }) {
    return TransferLimits(
      maxDocumentBytes: maxDocumentBytes ?? this.maxDocumentBytes,
      maxControlMessageBytes:
          maxControlMessageBytes ?? this.maxControlMessageBytes,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      handshakeTimeout: handshakeTimeout ?? this.handshakeTimeout,
      offerTimeout: offerTimeout ?? this.offerTimeout,
      approvalTimeout: approvalTimeout ?? this.approvalTimeout,
      verificationTimeout: verificationTimeout ?? this.verificationTimeout,
      inactivityTimeout: inactivityTimeout ?? this.inactivityTimeout,
      progressUpdateInterval:
          progressUpdateInterval ?? this.progressUpdateInterval,
      invitationTtl: invitationTtl ?? this.invitationTtl,
      preferredPort: preferredPort ?? this.preferredPort,
    );
  }
}
