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

  test(
    'persists and updates chapter location, progress and bookmarks',
    () async {
      await harness.progressRepository.saveProgress(
        ReadingProgress(
          documentId: harness.epubDocument.id,
          fraction: 0.42,
          locationIndex: 1,
          locationOffset: 0.35,
          locationRef: 'chapter2.xhtml',
          lastReadAt: DateTime(2026, 10, 24, 12),
          bookmarks: {1, 4},
        ),
      );

      var stored = await harness.progressRepository.watchProgress().first;
      var progress = stored[harness.epubDocument.id]!;
      expect(progress.fraction, 0.42);
      expect(progress.locationIndex, 1);
      expect(progress.locationOffset, 0.35);
      expect(progress.locationRef, 'chapter2.xhtml');
      expect(progress.bookmarks, {1, 4});
      expect(progress.lastReadAt, DateTime(2026, 10, 24, 12));

      await harness.progressRepository.saveProgress(
        progress.copyWith(
          fraction: 0.75,
          locationIndex: 0,
          locationRef: 'chapter1.xhtml',
          bookmarks: {2},
        ),
      );

      stored = await harness.progressRepository.watchProgress().first;
      progress = stored[harness.epubDocument.id]!;
      expect(stored, hasLength(1));
      expect(progress.fraction, 0.75);
      expect(progress.locationIndex, 0);
      expect(progress.locationRef, 'chapter1.xhtml');
      expect(progress.bookmarks, {2});
    },
  );

  test(
    'clearAll removes every reading position but keeps the library',
    () async {
      for (final document in [harness.epubDocument, harness.pdfDocument]) {
        await harness.progressRepository.saveProgress(
          ReadingProgress(documentId: document.id, fraction: 0.3),
        );
      }

      expect(
        await harness.progressRepository.watchProgress().first,
        hasLength(2),
      );
      await harness.progressRepository.clearAll();
      expect(await harness.progressRepository.watchProgress().first, isEmpty);
      expect(await harness.repository.getDocuments(), hasLength(2));
    },
  );
}
