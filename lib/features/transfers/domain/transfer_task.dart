import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer_task.freezed.dart';

enum TransferDirection { send, receive }

/// States shared by the UI, persistence layer, and transport.
///
/// A transfer is only marked [completed] after the receiver has seen every
/// declared byte, verified the SHA-256 digest, and committed the document to
/// the local library.
enum TransferStatus {
  connecting,
  awaitingApproval,
  transferring,
  verifying,
  completed,
  failed,
  cancelled,
}

@freezed
abstract class TransferTask with _$TransferTask {
  const TransferTask._();

  const factory TransferTask({
    required String id,
    required String? documentId,
    required String documentTitle,
    required String fileTypeLabel,
    required int sizeBytes,
    required TransferDirection direction,
    required String deviceName,
    required TransferStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(0) int transferredBytes,
    DateTime? completedAt,
    String? failureReason,
    String? note,
  }) = _TransferTask;

  double get progress {
    if (sizeBytes <= 0) return 0;
    return (transferredBytes / sizeBytes).clamp(0, 1);
  }

  int get percent => (progress * 100).round();

  bool get isActive => switch (status) {
    TransferStatus.connecting ||
    TransferStatus.awaitingApproval ||
    TransferStatus.transferring ||
    TransferStatus.verifying => true,
    _ => false,
  };

  bool get isTerminal => switch (status) {
    TransferStatus.completed ||
    TransferStatus.failed ||
    TransferStatus.cancelled => true,
    _ => false,
  };

  bool get isComplete => status == TransferStatus.completed;

  bool get isFailed => status == TransferStatus.failed;

  bool get isCancelled => status == TransferStatus.cancelled;

  bool get isAwaitingApproval => status == TransferStatus.awaitingApproval;

  bool get canCancel =>
      status == TransferStatus.connecting ||
      status == TransferStatus.awaitingApproval ||
      status == TransferStatus.transferring;

  String get directionLabel =>
      direction == TransferDirection.send ? 'Sending' : 'Receiving';

  String get statusLabel => switch (status) {
    TransferStatus.connecting => 'Connecting',
    TransferStatus.awaitingApproval => 'Awaiting approval',
    TransferStatus.transferring =>
      direction == TransferDirection.send ? 'Sending' : 'Receiving',
    TransferStatus.verifying => 'Verifying',
    TransferStatus.completed => 'Completed',
    TransferStatus.failed => 'Interrupted',
    TransferStatus.cancelled => 'Cancelled',
  };
}
