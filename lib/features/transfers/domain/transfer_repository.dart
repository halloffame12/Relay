import 'transfer_task.dart';

class TransferRepositoryException implements Exception {
  const TransferRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Persistence-only fields needed when a transfer starts.
class TransferDraft {
  const TransferDraft({
    required this.id,
    required this.direction,
    required this.documentTitle,
    required this.fileTypeLabel,
    required this.sizeBytes,
    required this.peerName,
    required this.status,
    required this.createdAt,
    this.documentId,
    this.transferredBytes = 0,
    this.tempFileName,
  });

  final String id;
  final TransferDirection direction;
  final String? documentId;
  final String documentTitle;
  final String fileTypeLabel;
  final int sizeBytes;
  final String peerName;
  final TransferStatus status;
  final DateTime createdAt;
  final int transferredBytes;

  /// Internal file name only. Remote document names are never used as paths.
  final String? tempFileName;
}

abstract interface class TransferRepository {
  Stream<List<TransferTask>> watchTransfers();

  Future<List<TransferTask>> getTransfers();

  Future<TransferTask?> findById(String id);

  Future<void> create(TransferDraft draft);

  /// Applies a validated state transition. Implementations reject transitions
  /// that could mark a transfer complete before verification.
  Future<void> updateStatus(
    String id,
    TransferStatus status, {
    int? transferredBytes,
    String? failureReason,
    String? note,
    String? documentId,
    DateTime? completedAt,
    bool clearTemporaryFile = false,
  });

  Future<void> updateProgress(String id, int transferredBytes);

  Future<void> updatePeerName(String id, String peerName);

  /// Marks every non-terminal row as failed. Used once at startup because this
  /// build does not implement resumable transfers.
  Future<int> failIncomplete(String reason);

  Future<void> delete(String id);

  Future<void> clearCompleted();
}
