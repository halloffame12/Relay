import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:relay/features/import/data/document_metadata_service.dart';
import 'package:relay/features/import/data/file_picker_document_import_service.dart';
import 'package:relay/features/import/domain/document_import_service.dart';
import 'package:relay/features/library/domain/document.dart';
import 'package:relay/features/library/domain/document_repository.dart';

import 'support/test_harness.dart';

void main() {
  late TestHarness harness;
  late FilePickerDocumentImportService service;
  late PickedImportFile picked;

  setUp(() async {
    harness = await TestHarness.create(seed: false);
    final source = File('test/fixtures/sample.epub');
    final probe = await harness.fileStore.probe(
      source.path,
      format: DocumentFormat.epub,
      maxBytes: 10 * 1024 * 1024,
    );
    picked = PickedImportFile(
      name: 'A Real Import.epub',
      path: source.path,
      sizeBytes: probe.sizeBytes,
      format: DocumentFormat.epub,
      sha256: probe.sha256,
    );
    service = FilePickerDocumentImportService(
      repository: harness.repository,
      fileStore: harness.fileStore,
      metadataService: const _FakeMetadataService(),
    );
  });

  tearDown(() async {
    await harness.dispose();
  });

  test(
    'imports a real file, persists metadata and detects duplicates',
    () async {
      final progress = <double>[];
      final result = await service.importFile(picked, onProgress: progress.add);

      expect(result.outcome, ImportOutcome.success);
      final document = result.document!;
      expect(document.title, 'Imported From A Real File');
      expect(document.author, 'Ada Lovelace');
      expect(document.fileName, 'A Real Import.epub');
      expect(document.storedFileName, isNotNull);
      expect(document.sha256, picked.sha256);
      expect(document.isImported, isTrue);
      expect(document.isMissing, isFalse);
      expect(document.sizeBytes, picked.sizeBytes);
      expect(progress.last, 1);
      expect(progress, isNotEmpty);
      expect(await harness.fileStore.exists(document.storedFileName!), isTrue);

      final duplicate = await service.findDuplicate(picked);
      expect(duplicate?.id, document.id);

      final second = await service.importFile(picked, onProgress: (_) {});
      expect(second.outcome, ImportOutcome.duplicate);
      expect(second.existingDocument?.id, document.id);
      expect(await harness.repository.getDocuments(), hasLength(1));
      expect(await harness.libraryDirectory.list().toList(), hasLength(1));
    },
  );

  test('cancelled imports leave no library record or copied file', () async {
    final token = ImportCancellationToken()..cancel();

    await expectLater(
      service.importFile(picked, onProgress: (_) {}, cancellation: token),
      throwsA(isA<ImportCancelledException>()),
    );

    expect(await harness.repository.getDocuments(), isEmpty);
    expect(
      await harness.libraryDirectory.exists()
          ? await harness.libraryDirectory.list().toList()
          : <FileSystemEntity>[],
      isEmpty,
    );
  });

  test('metadata failure removes the copied file', () async {
    final failing = FilePickerDocumentImportService(
      repository: harness.repository,
      fileStore: harness.fileStore,
      metadataService: const _FailingMetadataService(),
    );

    final result = await failing.importFile(picked, onProgress: (_) {});

    expect(result.outcome, ImportOutcome.failure);
    expect(await harness.repository.getDocuments(), isEmpty);
    expect(
      await harness.libraryDirectory.exists()
          ? await harness.libraryDirectory.list().toList()
          : <FileSystemEntity>[],
      isEmpty,
    );
  });

  test(
    'database failure removes the copied file instead of orphaning it',
    () async {
      final failing = FilePickerDocumentImportService(
        repository: _FailingRepository(),
        fileStore: harness.fileStore,
        metadataService: const _FakeMetadataService(),
      );

      final result = await failing.importFile(picked, onProgress: (_) {});

      expect(result.outcome, ImportOutcome.failure);
      expect(
        await harness.libraryDirectory.exists()
            ? await harness.libraryDirectory.list().toList()
            : <FileSystemEntity>[],
        isEmpty,
      );
    },
  );
}

class _FakeMetadataService implements DocumentMetadataService {
  const _FakeMetadataService();

  @override
  Future<ImportedDocumentMetadata> inspect({
    required String path,
    required String displayName,
    required DocumentFormat format,
  }) async {
    return const ImportedDocumentMetadata(
      title: 'Imported From A Real File',
      author: 'Ada Lovelace',
      language: 'en',
      description: 'A test import.',
    );
  }
}

class _FailingMetadataService implements DocumentMetadataService {
  const _FailingMetadataService();

  @override
  Future<ImportedDocumentMetadata> inspect({
    required String path,
    required String displayName,
    required DocumentFormat format,
  }) async {
    throw const FormatException('Not a readable document.');
  }
}

class _FailingRepository implements DocumentRepository {
  @override
  Future<void> addDocument(Document document) async {
    throw StateError('Simulated database failure.');
  }

  @override
  Future<Document?> findById(String id) async => null;

  @override
  Future<Document?> findBySha256(String sha256) async => null;

  @override
  Future<List<Document>> getDocuments() async => const [];

  @override
  Future<void> markOpened(String id) async {}

  @override
  Future<DocumentRemovalResult> removeDocument(String id) async {
    return const DocumentRemovalResult(fileRemoved: true);
  }

  @override
  Future<void> updatePageCount(String id, int? pageCount) async {}

  @override
  Stream<List<Document>> watchDocuments() => Stream.value(const []);
}
