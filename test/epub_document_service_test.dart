import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:relay/features/reader/data/epubx_document_service.dart';
import 'package:relay/features/reader/domain/epub_document.dart';

import 'support/epub_fixture.dart';

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
    'renders bounded raster images and skips SVG and remote sources',
    () async {
      final temp = await Directory.systemTemp.createTemp('relay_epub_images_');
      addTearDown(() => temp.delete(recursive: true));
      final file = File('${temp.path}/images.epub');
      await writeImageEpub(file);

      final book = await service.open(file.path);

      expect(book.title, 'Bidirectional Evil Title');
      expect(book.author, 'Ada Lovelace');
      expect(book.description, 'A book with an image.');
      expect(book.language, 'en-US');
      expect(book.chapters, hasLength(1));

      final blocks = book.chapters.single.blocks;
      final images = blocks.where((block) => block.kind == EpubBlockKind.image);
      expect(images, hasLength(1));
      final image = images.single;
      expect(image.image?.mimeType, 'image/png');
      expect(image.image?.bytes, isNotEmpty);
      expect(image.text, 'A pixel');

      final kinds = blocks.map((block) => block.kind).toList();
      expect(kinds, [
        EpubBlockKind.heading,
        EpubBlockKind.paragraph,
        EpubBlockKind.image,
        EpubBlockKind.paragraph,
      ]);
      expect(
        blocks.where((block) => block.text.contains('tracker')),
        isEmpty,
        reason: 'Remote image references must never be fetched.',
      );
    },
  );

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
