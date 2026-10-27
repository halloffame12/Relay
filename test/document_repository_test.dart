import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:relay/features/reader/domain/reading_progress.dart';

import 'support/test_harness.dart';

void main() {
  late TestHarness harness;

  setUp(() async {
    harness = await TestHarness.create();
  });

  tearDown(() async {
    await harness.dispose();
  });

  test('watches, finds and updates persisted library records', () async {
    final documents = await harness.repository.watchDocuments().first;
    expect(documents, hasLength(2));

    final byHash = await harness.repository.findBySha256(
      harness.epubDocument.sha256!,
    );
    expect(byHash?.title, 'The Quiet Orchard');
    expect(byHash?.fileName, 'The Quiet Orchard.epub');
    expect(
      await harness.fileStore.exists(harness.epubDocument.storedFileName!),
      isTrue,
    );

    expect(harness.pdfDocument.lastOpenedAt, isNull);
    await harness.repository.markOpened(harness.pdfDocument.id);
    await harness.repository.updatePageCount(harness.pdfDocument.id, 7);

    final updated = await harness.repository.findById(harness.pdfDocument.id);
    expect(updated?.lastOpenedAt, isNotNull);
    expect(updated?.pageCount, 7);
    expect(updated?.isMissing, isFalse);
  });

  test(
    'reports a missing managed file without discarding the record',
    () async {
      await harness.fileStore.delete(harness.epubDocument.storedFileName!);

      final document = await harness.repository.findById(
        harness.epubDocument.id,
      );
      expect(document, isNotNull);
      expect(document!.isMissing, isTrue);
      expect(await harness.repository.getDocuments(), hasLength(2));
    },
  );

  test('removal deletes only the managed copy and cascades progress', () async {
    await harness.progressRepository.saveProgress(
      ReadingProgress(
        documentId: harness.epubDocument.id,
        fraction: 0.4,
        locationIndex: 1,
        locationRef: 'chapter2.xhtml',
      ),
    );
    final managedPath = harness.fileStore.pathFor(
      harness.epubDocument.storedFileName!,
    );
    expect(await File(managedPath).exists(), isTrue);

    await harness.repository.removeDocument(harness.epubDocument.id);

    expect(await File(managedPath).exists(), isFalse);
    expect(await harness.repository.findById(harness.epubDocument.id), isNull);
    final progress = await harness.progressRepository.watchProgress().first;
    expect(progress, isEmpty);
    expect(await harness.repository.getDocuments(), hasLength(1));
  });
}
