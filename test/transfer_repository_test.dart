import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay/core/storage/app_database.dart';
import 'package:relay/features/transfers/data/drift_transfer_repository.dart';
import 'package:relay/features/transfers/domain/transfer_repository.dart';
import 'package:relay/features/transfers/domain/transfer_task.dart';

void main() {
  late AppDatabase database;
  late DriftTransferRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftTransferRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  TransferDraft draft({
    String id = 'tx-1',
    TransferDirection direction = TransferDirection.send,
    TransferStatus status = TransferStatus.connecting,
    int size = 100,
    String? tempFileName,
  }) {
    return TransferDraft(
      id: id,
      direction: direction,
      documentId: direction == TransferDirection.send ? 'doc-1' : null,
      documentTitle: 'Notes',
      fileTypeLabel: 'PDF',
      sizeBytes: size,
      peerName: 'Relay device',
      status: status,
      createdAt: DateTime(2026, 1, 1, 12),
      tempFileName: tempFileName,
    );
  }

  Future<void> moveToVerifying(String id, {int size = 100}) async {
    await repository.updateStatus(id, TransferStatus.awaitingApproval);
    await repository.updateStatus(id, TransferStatus.transferring);
    await repository.updateProgress(id, size);
    await repository.updateStatus(
      id,
      TransferStatus.verifying,
      transferredBytes: size,
    );
  }

  test('persists a record and streams it from the database', () async {
    await repository.create(draft());
    final records = await repository.watchTransfers().first;
    expect(records, hasLength(1));
    expect(records.single.status, TransferStatus.connecting);
    expect(records.single.transferredBytes, 0);
  });

  test('rejects duplicate transfer identifiers', () async {
    await repository.create(draft());
    expect(
      () => repository.create(draft()),
      throwsA(isA<TransferRepositoryException>()),
    );
  });

  test('enforces the complete transfer state sequence', () async {
    await repository.create(draft());
    await moveToVerifying('tx-1');
    await repository.updateStatus(
      'tx-1',
      TransferStatus.completed,
      transferredBytes: 100,
      documentId: 'doc-received',
    );
    final record = await repository.findById('tx-1');
    expect(record?.status, TransferStatus.completed);
    expect(record?.transferredBytes, 100);
    expect(record?.documentId, 'doc-received');
    expect(record?.completedAt, isNotNull);
  });

  test('cannot complete before verification or without every byte', () async {
    await repository.create(draft());
    await repository.updateStatus('tx-1', TransferStatus.awaitingApproval);
    expect(
      () => repository.updateStatus(
        'tx-1',
        TransferStatus.completed,
        transferredBytes: 100,
      ),
      throwsA(isA<TransferRepositoryException>()),
    );

    await repository.updateStatus('tx-1', TransferStatus.transferring);
    await repository.updateStatus(
      'tx-1',
      TransferStatus.verifying,
      transferredBytes: 50,
    );
    expect(
      () => repository.updateStatus(
        'tx-1',
        TransferStatus.completed,
        transferredBytes: 50,
      ),
      throwsA(isA<TransferRepositoryException>()),
    );
  });

  test('records monotonic real byte progress', () async {
    await repository.create(draft());
    await repository.updateStatus('tx-1', TransferStatus.awaitingApproval);
    await repository.updateStatus('tx-1', TransferStatus.transferring);
    await repository.updateProgress('tx-1', 40);
    expect((await repository.findById('tx-1'))?.transferredBytes, 40);

    expect(
      () => repository.updateProgress('tx-1', 30),
      throwsA(isA<TransferRepositoryException>()),
    );
    expect(
      () => repository.updateProgress('tx-1', 101),
      throwsA(isA<TransferRepositoryException>()),
    );
  });

  test('rejects progress outside the transferring state', () async {
    await repository.create(draft());
    expect(
      () => repository.updateProgress('tx-1', 10),
      throwsA(isA<TransferRepositoryException>()),
    );
  });

  test('active transfers cannot be deleted', () async {
    await repository.create(draft());
    expect(
      () => repository.delete('tx-1'),
      throwsA(isA<TransferRepositoryException>()),
    );
  });

  test('restart recovery fails every incomplete transfer', () async {
    await repository.create(draft(id: 'tx-1'));
    await repository.create(
      draft(id: 'tx-2', status: TransferStatus.transferring),
    );
    await repository.create(draft(id: 'tx-3'));
    await moveToVerifying('tx-3');
    await repository.updateStatus(
      'tx-3',
      TransferStatus.completed,
      transferredBytes: 100,
    );

    final changed = await repository.failIncomplete('Relay closed.');
    expect(changed, 2);
    final records = await repository.getTransfers();
    expect(
      records.where((record) => record.status == TransferStatus.failed),
      hasLength(2),
    );
    expect(
      records.firstWhere((record) => record.id == 'tx-3').status,
      TransferStatus.completed,
    );
  });

  test('clearing completed history leaves failure records', () async {
    await repository.create(draft(id: 'tx-1'));
    await moveToVerifying('tx-1');
    await repository.updateStatus(
      'tx-1',
      TransferStatus.completed,
      transferredBytes: 100,
    );
    await repository.create(draft(id: 'tx-2'));
    await repository.updateStatus(
      'tx-2',
      TransferStatus.cancelled,
      note: 'Cancelled',
    );

    await repository.clearCompleted();
    final records = await repository.getTransfers();
    expect(records, hasLength(1));
    expect(records.single.id, 'tx-2');
  });

  test('stores only a relative temporary file reference', () async {
    await repository.create(
      draft(
        id: 'tx-rx',
        direction: TransferDirection.receive,
        status: TransferStatus.awaitingApproval,
        tempFileName: 'tx-rx.part',
      ),
    );
    final row = await (database.select(
      database.transferEntries,
    )..where((table) => table.id.equals('tx-rx'))).getSingle();
    expect(row.tempFileName, 'tx-rx.part');
    expect(row.tempFileName, isNot(contains('/')));
    expect(row.tempFileName, isNot(contains('\\')));
  });
}
