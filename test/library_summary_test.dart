import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay/core/storage/database_providers.dart';
import 'package:relay/core/storage/storage_providers.dart';
import 'package:relay/features/library/application/library_providers.dart';
import 'package:relay/features/reader/application/reading_providers.dart';

import 'support/test_harness.dart';

void main() {
  test(
    'storage summary uses persisted file sizes, not invented totals',
    () async {
      final harness = await TestHarness.create();
      addTearDown(harness.dispose);

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(harness.database),
          documentFileStoreProvider.overrideWithValue(harness.fileStore),
        ],
      );
      addTearDown(container.dispose);

      container.listen(documentsProvider, (_, _) {}, fireImmediately: true);
      container.listen(
        readingProgressProvider,
        (_, _) {},
        fireImmediately: true,
      );
      await container.read(documentsProvider.future);
      await container.read(readingProgressProvider.future);

      final summary = container.read(librarySummaryProvider);
      final expectedTotal =
          harness.epubDocument.sizeBytes + harness.pdfDocument.sizeBytes;
      expect(summary.documentCount, 2);
      expect(summary.missingCount, 0);
      expect(summary.totalBytes, expectedTotal);
      expect(summary.epubBytes, harness.epubDocument.sizeBytes);
      expect(summary.pdfBytes, harness.pdfDocument.sizeBytes);
    },
  );

  test('missing managed files are excluded from stored bytes', () async {
    final harness = await TestHarness.create();
    addTearDown(harness.dispose);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(harness.database),
        documentFileStoreProvider.overrideWithValue(harness.fileStore),
      ],
    );
    addTearDown(container.dispose);

    await harness.fileStore.delete(harness.epubDocument.storedFileName!);
    container.listen(documentsProvider, (_, _) {}, fireImmediately: true);
    container.listen(readingProgressProvider, (_, _) {}, fireImmediately: true);
    await container.read(documentsProvider.future);
    await container.read(readingProgressProvider.future);

    final summary = container.read(librarySummaryProvider);
    expect(summary.documentCount, 2);
    expect(summary.missingCount, 1);
    expect(summary.totalBytes, harness.pdfDocument.sizeBytes);
    expect(summary.epubBytes, 0);
  });
}
