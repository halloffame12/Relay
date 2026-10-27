import 'package:flutter/foundation.dart';

enum EpubBlockKind { paragraph, heading, quote, listItem, code }

@immutable
class EpubBlock {
  const EpubBlock({required this.kind, required this.text});

  final EpubBlockKind kind;
  final String text;
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
    (total, block) => total + block.text.split(RegExp(r'\s+')).length,
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
