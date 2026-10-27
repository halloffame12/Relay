import 'package:drift/drift.dart';

import '../../../core/storage/app_database.dart';
import '../domain/transfer_repository.dart';
import '../domain/transfer_task.dart';

class DriftTransferRepository implements TransferRepository {
  DriftTransferRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<List<TransferTask>> watchTransfers() {
    final query = _database.select(_database.transferEntries)
      ..orderBy([(table) => OrderingTerm.desc(table.createdAt)]);
    return query.watch().map((rows) => rows.map(_mapRow).toList());
  }

  @override
  Future<List<TransferTask>> getTransfers() async {
    final query = _database.select(_database.transferEntries)
      ..orderBy([(table) => OrderingTerm.desc(table.createdAt)]);
    return (await query.get()).map(_mapRow).toList();
  }

  @override
  Future<TransferTask?> findById(String id) async {
    final row = await (_database.select(
      _database.transferEntries,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  @override
  Future<void> create(TransferDraft draft) async {
    final peer = draft.peerName.trim();
    if (peer.isEmpty || peer.length > 80) {
      throw const TransferRepositoryException(
        'The transfer peer name is invalid.',
      );
    }
    try {
      await _database
          .into(_database.transferEntries)
          .insert(
            TransferEntriesCompanion.insert(
              id: draft.id,
              direction: draft.direction.name,
              documentId: Value(draft.documentId),
              documentTitle: draft.documentTitle,
              fileTypeLabel: draft.fileTypeLabel,
              sizeBytes: draft.sizeBytes,
              transferredBytes: Value(draft.transferredBytes),
              state: draft.status.name,
              peerName: peer,
              createdAt: draft.createdAt,
              updatedAt: draft.createdAt,
              tempFileName: Value(draft.tempFileName),
            ),
          );
    } catch (error) {
      if (error is TransferRepositoryException) rethrow;
      throw const TransferRepositoryException(
        'A transfer with this identifier already exists.',
      );
    }
  }

  @override
  Future<void> updateStatus(
    String id,
    TransferStatus status, {
    int? transferredBytes,
    String? failureReason,
    String? note,
    String? documentId,
    DateTime? completedAt,
    bool clearTemporaryFile = false,
  }) {
    return _database.transaction(() async {
      final row = await _row(id);
      final current = TransferStatus.values.byName(row.state);
      if (current != status &&
          !_allowedTransitions[current]!.contains(status)) {
        throw TransferRepositoryException(
          'Transfer ${row.id} cannot move from ${current.name} to '
          '${status.name}.',
        );
      }

      final bytes = transferredBytes ?? row.transferredBytes;
      if (bytes < 0 || bytes > row.sizeBytes) {
        throw const TransferRepositoryException(
          'The transfer byte count is outside the document size.',
        );
      }
      if (status == TransferStatus.completed && bytes != row.sizeBytes) {
        throw const TransferRepositoryException(
          'A transfer cannot complete before every byte is verified.',
        );
      }

      await (_database.update(
        _database.transferEntries,
      )..where((table) => table.id.equals(id))).write(
        TransferEntriesCompanion(
          state: Value(status.name),
          transferredBytes: Value(bytes),
          updatedAt: Value(DateTime.now()),
          failureReason: Value(failureReason),
          note: Value(note),
          documentId: documentId == null
              ? const Value.absent()
              : Value(documentId),
          completedAt: status == TransferStatus.completed
              ? Value(completedAt ?? DateTime.now())
              : const Value(null),
          tempFileName: clearTemporaryFile
              ? const Value(null)
              : const Value.absent(),
        ),
      );
    });
  }

  @override
  Future<void> updateProgress(String id, int transferredBytes) {
    return _database.transaction(() async {
      final row = await _row(id);
      final current = TransferStatus.values.byName(row.state);
      if (current != TransferStatus.transferring) {
        throw TransferRepositoryException(
          'Progress cannot be recorded while a transfer is ${current.name}.',
        );
      }
      if (transferredBytes < row.transferredBytes ||
          transferredBytes < 0 ||
          transferredBytes > row.sizeBytes) {
        throw const TransferRepositoryException(
          'The transfer byte count is invalid.',
        );
      }
      if (transferredBytes == row.transferredBytes) return;
      await (_database.update(
        _database.transferEntries,
      )..where((table) => table.id.equals(id))).write(
        TransferEntriesCompanion(
          transferredBytes: Value(transferredBytes),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> updatePeerName(String id, String peerName) async {
    final trimmed = peerName.trim();
    if (trimmed.isEmpty || trimmed.length > 80) {
      throw const TransferRepositoryException(
        'The transfer peer name is invalid.',
      );
    }
    await (_database.update(
      _database.transferEntries,
    )..where((table) => table.id.equals(id))).write(
      TransferEntriesCompanion(
        peerName: Value(trimmed),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<int> failIncomplete(String reason) async {
    final activeNames = _activeStates.map((state) => state.name).toList();
    return (_database.update(
      _database.transferEntries,
    )..where((table) => table.state.isIn(activeNames))).write(
      TransferEntriesCompanion(
        state: Value(TransferStatus.failed.name),
        failureReason: Value(reason),
        updatedAt: Value(DateTime.now()),
        completedAt: const Value(null),
        tempFileName: const Value(null),
      ),
    );
  }

  @override
  Future<void> delete(String id) {
    return _database.transaction(() async {
      final row = await _row(id);
      final current = TransferStatus.values.byName(row.state);
      if (!_terminalStates.contains(current)) {
        throw const TransferRepositoryException(
          'An active transfer cannot be deleted. Cancel it first.',
        );
      }
      await (_database.delete(
        _database.transferEntries,
      )..where((table) => table.id.equals(id))).go();
    });
  }

  @override
  Future<void> clearCompleted() async {
    await (_database.delete(_database.transferEntries)
          ..where((table) => table.state.equals(TransferStatus.completed.name)))
        .go();
  }

  Future<TransferRow> _row(String id) async {
    final row = await (_database.select(
      _database.transferEntries,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    if (row == null) {
      throw const TransferRepositoryException('The transfer was not found.');
    }
    return row;
  }

  TransferTask _mapRow(TransferRow row) {
    return TransferTask(
      id: row.id,
      documentId: row.documentId,
      documentTitle: row.documentTitle,
      fileTypeLabel: row.fileTypeLabel,
      sizeBytes: row.sizeBytes,
      direction: TransferDirection.values.byName(row.direction),
      deviceName: row.peerName,
      status: TransferStatus.values.byName(row.state),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      transferredBytes: row.transferredBytes,
      completedAt: row.completedAt,
      failureReason: row.failureReason,
      note: row.note,
    );
  }

  static const Set<TransferStatus> _terminalStates = {
    TransferStatus.completed,
    TransferStatus.failed,
    TransferStatus.cancelled,
  };

  static const Set<TransferStatus> _activeStates = {
    TransferStatus.connecting,
    TransferStatus.awaitingApproval,
    TransferStatus.transferring,
    TransferStatus.verifying,
  };

  static const Map<TransferStatus, Set<TransferStatus>> _allowedTransitions = {
    TransferStatus.connecting: {
      TransferStatus.awaitingApproval,
      TransferStatus.failed,
      TransferStatus.cancelled,
    },
    TransferStatus.awaitingApproval: {
      TransferStatus.transferring,
      TransferStatus.failed,
      TransferStatus.cancelled,
    },
    TransferStatus.transferring: {
      TransferStatus.verifying,
      TransferStatus.failed,
      TransferStatus.cancelled,
    },
    TransferStatus.verifying: {TransferStatus.completed, TransferStatus.failed},
    TransferStatus.completed: {},
    TransferStatus.failed: {},
    TransferStatus.cancelled: {},
  };
}
