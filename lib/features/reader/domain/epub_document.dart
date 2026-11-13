import 'package:flutter/foundation.dart';

enum EpubBlockKind { paragraph, heading, quote, listItem, code, image }

@immutable
class EpubImage {
  const EpubImage({
    required this.bytes,
    required this.mimeType,
    this.altText = '',
  });

  final Uint8List bytes;
  final String mimeType;
  final String altText;
}

@immutable
class EpubBlock {
  const EpubBlock({required this.kind, required this.text, this.image});

  final EpubBlockKind kind;
  final String text;
  final EpubImage? image;
}

@immutable
class EpubChapter {
  const EpubChapter({
    required this.id,
    required this.title,
    required this.blocks,
  });

  final String id;
  final String title;
  final List<EpubBlock> blocks;

  int get wordCount => blocks.fold(
    0,
    (total, block) =>
        total +
        (block.kind == EpubBlockKind.image || block.text.trim().isEmpty
            ? 0
            : block.text.split(RegExp(r'\s+')).length),
  );

  int get readingMinutes => (wordCount / 220).ceil().clamp(1, 999);

  String? get firstParagraph {
    for (final block in blocks) {
      if (block.kind == EpubBlockKind.paragraph) return block.text;
    }
    return null;
  }
}

@immutable
class EpubDocument {
  const EpubDocument({
    required this.title,
    required this.author,
    required this.language,
    required this.chapters,
    this.description = '',
  });

  final String title;
  final String author;
  final String language;
  final List<EpubChapter> chapters;
  final String description;

  int get wordCount =>
      chapters.fold(0, (total, chapter) => total + chapter.wordCount);

  int get readingMinutes => (wordCount / 220).ceil().clamp(1, 999);
}

class EpubFormatException implements Exception {
  const EpubFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class EpubDocumentService {
  Future<EpubDocument> open(String path, {String? fallbackTitle});
}
