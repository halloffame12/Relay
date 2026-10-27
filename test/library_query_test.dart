import 'package:flutter_test/flutter_test.dart';
import 'support/sample_documents.dart';
import 'package:relay/features/library/domain/document.dart';
import 'package:relay/features/library/domain/library_item.dart';
import 'package:relay/features/library/domain/library_query.dart';
import 'package:relay/features/reader/domain/reading_progress.dart';

void main() {
  final documents = buildSampleDocuments(reference: DateTime(2026, 1, 10));

  List<LibraryItem> plainItems() => [
    for (final document in documents) LibraryItem(document: document),
  ];

  Document documentById(String id) =>
      documents.firstWhere((document) => document.id == id);

  test('search matches titles, authors and sources case-insensitively', () {
    final byTitle = applyLibraryQuery(
      plainItems(),
      const LibraryQuery(search: 'orchard'),
    );
    expect(byTitle, hasLength(1));
    expect(byTitle.single.document.id, 'orchard-year');

    final byAuthor = applyLibraryQuery(
      plainItems(),
      const LibraryQuery(search: 'LENA ORTIZ'),
    );
    expect(byAuthor, hasLength(1));
    expect(byAuthor.single.document.title, 'Designing for Attention');

    final bySource = applyLibraryQuery(
      plainItems(),
      const LibraryQuery(search: 'northern editions'),
    );
    expect(bySource, hasLength(1));
    expect(bySource.single.document.title, 'Letters from the Northern Line');

    final renamed = documentById(
      'field-notes-quiet-places',
    ).copyWith(fileName: 'quiet-places-field-notes.epub');
    final byFileName = applyLibraryQuery([
      LibraryItem(document: renamed),
    ], const LibraryQuery(search: 'FIELD-NOTES.EPUB'));
    expect(byFileName, hasLength(1));
    expect(byFileName.single.document.id, 'field-notes-quiet-places');
  });

  test('format filter narrows the collection to PDF or EPUB', () {
    final pdfOnly = applyLibraryQuery(
      plainItems(),
      const LibraryQuery(
        filters: LibraryFilters(formats: {DocumentFormat.pdf}),
      ),
    );
    expect(pdfOnly, isNotEmpty);
    expect(pdfOnly.every((item) => item.document.isPdf), isTrue);

    final epubOnly = applyLibraryQuery(
      plainItems(),
      const LibraryQuery(
        filters: LibraryFilters(formats: {DocumentFormat.epub}),
      ),
    );
    expect(epubOnly, isNotEmpty);
    expect(epubOnly.every((item) => item.document.isPdf), isFalse);
    expect(pdfOnly.length + epubOnly.length, documents.length);
  });

  test('reading status filter uses persisted progress', () {
    final items = [
      LibraryItem(
        document: documentById('field-notes-quiet-places'),
        progress: const ReadingProgress(
          documentId: 'field-notes-quiet-places',
          fraction: 0.42,
        ),
      ),
      LibraryItem(
        document: documentById('orchard-year'),
        progress: const ReadingProgress(
          documentId: 'orchard-year',
          fraction: 1,
        ),
      ),
      LibraryItem(document: documentById('paper-archive')),
    ];

    final finished = applyLibraryQuery(
      items,
      const LibraryQuery(
        filters: LibraryFilters(statuses: {LibraryReadingStatus.finished}),
      ),
    );
    expect(finished, hasLength(1));
    expect(finished.single.document.id, 'orchard-year');

    final reading = applyLibraryQuery(
      items,
      const LibraryQuery(
        filters: LibraryFilters(statuses: {LibraryReadingStatus.reading}),
      ),
    );
    expect(reading, hasLength(1));
    expect(reading.single.document.id, 'field-notes-quiet-places');
  });

  test('opening a document counts as reading even at its first position', () {
    final item = LibraryItem(
      document: documentById('paper-archive'),
      progress: ReadingProgress(
        documentId: 'paper-archive',
        lastReadAt: DateTime(2026, 10, 24),
      ),
    );

    expect(item.hasProgress, isTrue);
    expect(item.readingStatus, LibraryReadingStatus.reading);
    expect(item.percent, 0);
  });

  test('title sorting is alphabetical and stable for the collection', () {
    final sorted = applyLibraryQuery(
      plainItems(),
      const LibraryQuery(sort: LibrarySort.title),
    );
    final titles = [for (final item in sorted) item.document.title];
    final expected = [...titles]
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    expect(titles, expected);
  });

  test('largest-file sorting puts the biggest document first', () {
    final sorted = applyLibraryQuery(
      plainItems(),
      const LibraryQuery(sort: LibrarySort.fileSize),
    );
    expect(sorted.first.document.title, 'The Paper Archive');
    for (var index = 1; index < sorted.length; index++) {
      expect(
        sorted[index - 1].document.sizeBytes,
        greaterThanOrEqualTo(sorted[index].document.sizeBytes),
      );
    }
  });

  test('search combines with filters rather than replacing them', () {
    final result = applyLibraryQuery(
      plainItems(),
      const LibraryQuery(
        search: 'the',
        filters: LibraryFilters(formats: {DocumentFormat.epub}),
      ),
    );
    expect(result, isNotEmpty);
    expect(result.every((item) => !item.document.isPdf), isTrue);
    expect(
      result.every(
        (item) =>
            item.document.title.toLowerCase().contains('the') ||
            item.document.author.toLowerCase().contains('the') ||
            item.document.source.toLowerCase().contains('the'),
      ),
      isTrue,
    );
  });
}
