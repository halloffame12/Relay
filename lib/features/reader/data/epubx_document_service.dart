import 'dart:io';

import 'package:epubx/epubx.dart' as epubx;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../domain/epub_document.dart';

/// Parses an EPUB into Relay's reader model. The original file is copied into
/// the app library first; this service only reads the managed copy.
class EpubxDocumentService implements EpubDocumentService {
  @override
  Future<EpubDocument> open(String path, {String? fallbackTitle}) async {
    try {
      final bytes = await File(path).readAsBytes();
      if (bytes.isEmpty) {
        throw const EpubFormatException('The EPUB file is empty.');
      }
      final book = await epubx.EpubReader.readBook(bytes);
      final chapters = _chaptersFromBook(book);
      if (chapters.isEmpty) {
        throw const EpubFormatException(
          'Relay could not find readable chapters in this EPUB.',
        );
      }
      final metadata = book.Schema?.Package?.Metadata;
      final title = _firstNonEmpty([
        book.Title,
        ...?metadata?.Titles,
      ], fallback: fallbackTitle ?? 'Untitled EPUB');
      final author = _firstNonEmpty([
        book.Author,
        ...?metadata?.Creators?.map((creator) => creator.Creator),
      ], fallback: 'Unknown author');
      final language = _firstNonEmpty([
        ...?metadata?.Languages,
      ], fallback: 'Not set');
      return EpubDocument(
        title: title,
        author: author,
        language: language,
        description: metadata?.Description?.trim() ?? '',
        chapters: chapters,
      );
    } on EpubFormatException {
      rethrow;
    } on FileSystemException {
      throw const EpubFormatException(
        'Relay could not read the EPUB file on this device.',
      );
    } catch (_) {
      throw const EpubFormatException(
        'This file could not be read as an EPUB. It may be malformed or '
        'protected.',
      );
    }
  }

  List<EpubChapter> _chaptersFromBook(epubx.EpubBook book) {
    final result = <EpubChapter>[];
    final seen = <String>{};
    final navChapters = book.Chapters ?? const <epubx.EpubChapter>[];
    for (final chapter in navChapters) {
      _flattenChapter(chapter, result, seen);
    }
    if (result.isNotEmpty) return result;

    // Some EPUBs ship without an NCX/nav document. Fall back to the reading
    // order in the OPF spine rather than refusing to open the book.
    final manifestItems =
        book.Schema?.Package?.Manifest?.Items ??
        const <epubx.EpubManifestItem>[];
    final byId = <String, epubx.EpubManifestItem>{
      for (final item in manifestItems)
        if (item.Id != null) item.Id!: item,
    };
    final htmlFiles =
        book.Content?.Html ?? const <String, epubx.EpubTextContentFile>{};
    final spineItems =
        book.Schema?.Package?.Spine?.Items ?? const <epubx.EpubSpineItemRef>[];
    var index = 0;
    for (final spineItem in spineItems) {
      final manifest = byId[spineItem.IdRef];
      final href = manifest?.Href;
      if (href == null) continue;
      final content = htmlFiles[href]?.Content;
      if (content == null) continue;
      final blocks = _parseHtmlBlocks(content);
      if (blocks.isEmpty) continue;
      final id = 'spine-$index-$href';
      index++;
      result.add(
        EpubChapter(
          id: id,
          title: _titleForBlocks(blocks, 'Chapter ${result.length + 1}'),
          blocks: blocks,
        ),
      );
    }
    return result;
  }

  void _flattenChapter(
    epubx.EpubChapter chapter,
    List<EpubChapter> result,
    Set<String> seen,
  ) {
    final html = chapter.HtmlContent;
    if (html != null && html.trim().isNotEmpty) {
      final blocks = _parseHtmlBlocks(html);
      if (blocks.isNotEmpty) {
        final source =
            chapter.ContentFileName ?? 'chapter-${result.length + 1}';
        final anchor = chapter.Anchor?.trim();
        final id = anchor == null || anchor.isEmpty
            ? source
            : '$source#$anchor';
        if (seen.add(id)) {
          final title = _firstNonEmpty([
            chapter.Title,
            _titleForBlocks(blocks, 'Chapter ${result.length + 1}'),
          ], fallback: 'Chapter ${result.length + 1}');
          result.add(EpubChapter(id: id, title: title, blocks: blocks));
        }
      }
    }
    for (final child in chapter.SubChapters ?? const <epubx.EpubChapter>[]) {
      _flattenChapter(child, result, seen);
    }
  }

  List<EpubBlock> _parseHtmlBlocks(String source) {
    final document = html_parser.parse(source);
    final body = document.body;
    if (body == null) return const [];
    for (final unwanted in body.querySelectorAll(
      'script, style, nav, svg, audio, video, iframe, noscript',
    )) {
      unwanted.remove();
    }

    final blocks = <EpubBlock>[];
    final added = <dom.Element>{};
    const selectors = 'h1, h2, h3, h4, h5, h6, p, blockquote, li, pre';
    for (final element in body.querySelectorAll(selectors)) {
      if (_hasAddedAncestor(element, added)) continue;
      final text = _cleanText(_textOf(element));
      if (text.isEmpty) continue;
      final tag = element.localName ?? '';
      final kind = switch (tag) {
        'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6' => EpubBlockKind.heading,
        'blockquote' => EpubBlockKind.quote,
        'li' => EpubBlockKind.listItem,
        'pre' => EpubBlockKind.code,
        _ => EpubBlockKind.paragraph,
      };
      blocks.add(EpubBlock(kind: kind, text: text));
      added.add(element);
    }

    if (blocks.isEmpty) {
      final text = _cleanText(_textOf(body));
      if (text.isNotEmpty) {
        blocks.add(EpubBlock(kind: EpubBlockKind.paragraph, text: text));
      }
    }
    return blocks;
  }

  bool _hasAddedAncestor(dom.Element element, Set<dom.Element> added) {
    dom.Node? current = element.parent;
    while (current != null) {
      if (current is dom.Element && added.contains(current)) return true;
      current = current.parent;
    }
    return false;
  }

  String _textOf(dom.Node node) {
    final buffer = StringBuffer();
    void visit(dom.Node node) {
      if (node is dom.Text) {
        buffer.write(node.data);
        return;
      }
      if (node is dom.Element) {
        final tag = node.localName;
        if (tag == 'br') {
          buffer.write(' ');
          return;
        }
        if (tag == 'script' || tag == 'style') return;
      }
      for (final child in node.nodes) {
        visit(child);
        if (child is dom.Element &&
            (child.localName == 'p' ||
                child.localName == 'div' ||
                child.localName == 'li' ||
                child.localName == 'h1' ||
                child.localName == 'h2' ||
                child.localName == 'h3')) {
          buffer.write(' ');
        }
      }
    }

    visit(node);
    return buffer.toString();
  }

  String _cleanText(String value) {
    return value
        .replaceAll('\u00A0', ' ')
        .replaceAll('\u200B', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _titleForBlocks(List<EpubBlock> blocks, String fallback) {
    for (final block in blocks) {
      if (block.kind == EpubBlockKind.heading && block.text.length <= 120) {
        return block.text;
      }
    }
    return fallback;
  }

  String _firstNonEmpty(List<String?> values, {required String fallback}) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return fallback;
  }
}
