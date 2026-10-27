import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:relay/features/reader/data/epubx_document_service.dart';
import 'package:relay/features/reader/domain/epub_document.dart';

void main() {
  final service = EpubxDocumentService();

  test('parses a real EPUB file into chapters and readable blocks', () async {
    final book = await service.open('test/fixtures/sample.epub');

    expect(book.title, 'The Quiet Orchard');
    expect(book.author, 'Mara Venn');
    expect(book.language, 'en');
    expect(book.chapters, hasLength(2));
    expect(book.chapters.first.title, 'Attention');
    expect(book.chapters.last.title, 'The Orchard');
    expect(book.chapters.first.id, 'chapter1.xhtml');
    expect(book.chapters.first.blocks, isNotEmpty);
    expect(
      book.chapters.first.blocks.where(
        (block) => block.kind == EpubBlockKind.quote,
      ),
      isNotEmpty,
    );
    expect(
      book.chapters.first.blocks.where(
        (block) => block.kind == EpubBlockKind.listItem,
      ),
      hasLength(2),
    );
    expect(book.wordCount, greaterThan(10));
  });

  test(
    'reports malformed EPUB containers without leaking parser errors',
    () async {
      final temp = await Directory.systemTemp.createTemp('relay_epub_test_');
      addTearDown(() => temp.delete(recursive: true));
      final file = File('${temp.path}/broken.epub');
      await file.writeAsBytes([0x50, 0x4B, 0x03, 0x04, 1, 2, 3, 4]);

      await expectLater(
        service.open(file.path),
        throwsA(isA<EpubFormatException>()),
      );
    },
  );

  test('reports an unreadable path as an EPUB format error', () async {
    await expectLater(
      service.open('test/fixtures/does-not-exist.epub'),
      throwsA(isA<EpubFormatException>()),
    );
  });
}
