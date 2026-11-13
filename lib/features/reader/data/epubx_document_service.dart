import 'dart:io';
import 'dart:typed_data';

import 'package:epubx/epubx.dart' as epubx;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../../../core/utils/untrusted_text.dart';
import '../domain/epub_document.dart';

/// Parses an EPUB into Relay's reader model. The original file is copied into
/// the app library first; this service only reads the managed copy.
///
/// Only bounded, raster images referenced by reading-order HTML are exposed to
/// the reader. SVG (which can carry script) and remote references are ignored.
class EpubxDocumentService implements EpubDocumentService {
  static const _maxImageBytes = 8 * 1024 * 1024;
  static const _maxTotalImageBytes = 24 * 1024 * 1024;
  static const _maxImagesPerBook = 40;

  @override
  Future<EpubDocument> open(String path, {String? fallbackTitle}) async {
    try {
      final bytes = await File(path).readAsBytes();
      if (bytes.isEmpty) {
        throw const EpubFormatException('The EPUB file is empty.');
      }
      final book = await epubx.EpubReader.readBook(bytes);
      final images = _EpubImageIndex(book);
      final chapters = _chaptersFromBook(book, images);
      if (chapters.isEmpty) {
        throw const EpubFormatException(
          'Relay could not find readable chapters in this EPUB.',
        );
      }
      final metadata = book.Schema?.Package?.Metadata;
      var title = UntrustedText.clean(
        _firstNonEmpty([
          book.Title,
          ...?metadata?.Titles,
        ], fallback: fallbackTitle ?? 'Untitled EPUB'),
        maxLength: UntrustedText.maxTitleLength,
      );
      if (title.isEmpty) title = 'Untitled EPUB';
      final author = UntrustedText.clean(
        _firstNonEmpty([
          book.Author,
          ...?metadata?.Creators?.map((creator) => creator.Creator),
        ], fallback: 'Unknown author'),
        maxLength: UntrustedText.maxAuthorLength,
      );
      final language = UntrustedText.language(
        _firstNonEmpty([...?metadata?.Languages], fallback: 'Not set'),
      );
      final description = UntrustedText.clean(
        metadata?.Description,
        maxLength: UntrustedText.maxDescriptionLength,
      );
      return EpubDocument(
        title: title,
        author: author.isEmpty ? 'Unknown author' : author,
        language: language.isEmpty ? 'Not set' : language,
        description: description,
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

  List<EpubChapter> _chaptersFromBook(
    epubx.EpubBook book,
    _EpubImageIndex images,
  ) {
    final result = <EpubChapter>[];
    final seen = <String>{};
    final navChapters = book.Chapters ?? const <epubx.EpubChapter>[];
    for (final chapter in navChapters) {
      _flattenChapter(chapter, result, seen, images);
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
      final blocks = _parseHtmlBlocks(
        content,
        contentPath: href,
        images: images,
      );
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
    _EpubImageIndex images,
  ) {
    final html = chapter.HtmlContent;
    if (html != null && html.trim().isNotEmpty) {
      final contentPath = chapter.ContentFileName;
      final blocks = _parseHtmlBlocks(
        html,
        contentPath: contentPath,
        images: images,
      );
      if (blocks.isNotEmpty) {
        final source = contentPath ?? 'chapter-${result.length + 1}';
        final anchor = chapter.Anchor?.trim();
        final id = anchor == null || anchor.isEmpty
            ? source
            : '$source#$anchor';
        if (seen.add(id)) {
          final title = _firstNonEmpty([
            chapter.Title,
            _titleForBlocks(blocks, 'Chapter ${result.length + 1}'),
          ], fallback: 'Chapter ${result.length + 1}');
          result.add(
            EpubChapter(
              id: id,
              title: UntrustedText.clean(
                title,
                maxLength: UntrustedText.maxChapterTitleLength,
              ),
              blocks: blocks,
            ),
          );
        }
      }
    }
    for (final child in chapter.SubChapters ?? const <epubx.EpubChapter>[]) {
      _flattenChapter(child, result, seen, images);
    }
  }

  List<EpubBlock> _parseHtmlBlocks(
    String source, {
    String? contentPath,
    required _EpubImageIndex images,
  }) {
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
    const selectors = 'h1, h2, h3, h4, h5, h6, p, blockquote, li, pre, img';
    for (final element in body.querySelectorAll(selectors)) {
      if (_hasAddedAncestor(element, added)) continue;
      final tag = element.localName ?? '';
      if (tag == 'img') {
        final image = contentPath == null
            ? null
            : images.resolve(element.attributes['src'], contentPath);
        if (image == null) continue;
        final alt = UntrustedText.clean(
          element.attributes['alt'],
          maxLength: 300,
        );
        blocks.add(
          EpubBlock(kind: EpubBlockKind.image, text: alt, image: image),
        );
        added.add(element);
        continue;
      }
      final text = _cleanText(_textOf(element));
      if (text.isEmpty) continue;
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
    return UntrustedText.clean(value, maxLength: UntrustedText.maxBlockLength);
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

class _EpubImageCandidate {
  const _EpubImageCandidate({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}

/// Indexes raster image entries that were already extracted by epubx.
///
/// Entries are bounded individually and again across the whole book so opening
/// an image-heavy EPUB cannot grow the reader's memory without limit. SVG is
/// deliberately excluded: Flutter would not execute it, but there is no reason
/// to carry an executable document format into the rendering layer.
class _EpubImageIndex {
  _EpubImageIndex(epubx.EpubBook book) {
    final sources =
        book.Content?.Images ?? const <String, epubx.EpubByteContentFile>{};
    for (final entry in sources.entries) {
      final path = _normalizePath(entry.key);
      if (path.isEmpty) continue;
      final file = entry.value;
      final mimeType = _rasterMimeType(file.ContentMimeType);
      if (mimeType == null) continue;
      final content = file.Content;
      if (content == null || content.isEmpty) continue;
      if (content.length > EpubxDocumentService._maxImageBytes) continue;
      final bytes = content is Uint8List
          ? content
          : Uint8List.fromList(content);
      if (!_matchesMagic(bytes, mimeType)) continue;
      _candidates[path] = _EpubImageCandidate(bytes: bytes, mimeType: mimeType);
    }
  }

  final Map<String, _EpubImageCandidate> _candidates = {};
  var _imagesUsed = 0;
  var _bytesRemaining = EpubxDocumentService._maxTotalImageBytes;

  EpubImage? resolve(String? href, String contentPath) {
    if (href == null) return null;
    final path = _resolvePath(contentPath, href);
    if (path.isEmpty) return null;
    final candidate = _candidates[path];
    if (candidate == null) return null;
    if (_imagesUsed >= EpubxDocumentService._maxImagesPerBook) return null;
    if (candidate.bytes.length > _bytesRemaining) return null;
    _imagesUsed++;
    _bytesRemaining -= candidate.bytes.length;
    return EpubImage(bytes: candidate.bytes, mimeType: candidate.mimeType);
  }

  static String _resolvePath(String contentPath, String href) {
    final contentSegments = _pathSegments(contentPath);
    final base = contentSegments == null || contentSegments.length < 2
        ? ''
        : contentSegments.sublist(0, contentSegments.length - 1).join('/');
    final segments = _pathSegments(href, base: base);
    return segments?.join('/') ?? '';
  }

  static String _normalizePath(String value) {
    return _pathSegments(value)?.join('/') ?? '';
  }

  static List<String>? _pathSegments(String raw, {String? base}) {
    var value = raw.trim().replaceAll('\\', '/');
    if (value.isEmpty) return null;
    final hash = value.indexOf('#');
    if (hash >= 0) value = value.substring(0, hash);
    final query = value.indexOf('?');
    if (query >= 0) value = value.substring(0, query);
    if (value.isEmpty) return null;
    final rooted = value.startsWith('/');
    final uri = Uri.tryParse(value);
    if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
    try {
      value = Uri.decodeFull(value);
    } catch (_) {
      return null;
    }
    if (rooted) value = value.substring(1);
    final combined = base == null || base.isEmpty || rooted
        ? value
        : '$base/$value';
    final result = <String>[];
    for (final part in combined.split('/')) {
      if (part.isEmpty || part == '.') continue;
      if (part == '..') {
        if (result.isEmpty) return null;
        result.removeLast();
      } else {
        result.add(part);
      }
    }
    return result;
  }

  static String? _rasterMimeType(String? raw) {
    final mimeType = raw?.toLowerCase().split(';').first.trim();
    return switch (mimeType) {
      'image/png' => 'image/png',
      'image/jpeg' => 'image/jpeg',
      'image/gif' => 'image/gif',
      _ => null,
    };
  }

  static bool _matchesMagic(Uint8List bytes, String mimeType) {
    return switch (mimeType) {
      'image/png' =>
        bytes.length >= 8 &&
            bytes[0] == 0x89 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x4E &&
            bytes[3] == 0x47 &&
            bytes[4] == 0x0D &&
            bytes[5] == 0x0A &&
            bytes[6] == 0x1A &&
            bytes[7] == 0x0A,
      'image/jpeg' =>
        bytes.length >= 3 &&
            bytes[0] == 0xFF &&
            bytes[1] == 0xD8 &&
            bytes[2] == 0xFF,
      'image/gif' =>
        bytes.length >= 6 &&
            bytes[0] == 0x47 &&
            bytes[1] == 0x49 &&
            bytes[2] == 0x46 &&
            bytes[3] == 0x38 &&
            (bytes[4] == 0x37 || bytes[4] == 0x39) &&
            bytes[5] == 0x61,
      _ => false,
    };
  }
}
