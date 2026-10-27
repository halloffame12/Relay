import 'package:path/path.dart' as p;

import '../../library/domain/document.dart';
import '../../reader/domain/epub_document.dart';
import '../../reader/domain/pdf_document.dart';

class ImportedDocumentMetadata {
  const ImportedDocumentMetadata({
    required this.title,
    required this.author,
    required this.language,
    required this.description,
    this.pageCount,
  });

  final String title;
  final String author;
  final String language;
  final String description;
  final int? pageCount;
}

abstract interface class DocumentMetadataService {
  Future<ImportedDocumentMetadata> inspect({
    required String path,
    required String displayName,
    required DocumentFormat format,
  });
}

/// Extracts only the metadata Relay stores; the document is later re-opened by
/// the reader from the managed copy.
class LocalDocumentMetadataService implements DocumentMetadataService {
  LocalDocumentMetadataService({
    required EpubDocumentService epubService,
    required PdfDocumentService pdfService,
  }) : _epubService = epubService,
       _pdfService = pdfService;

  final EpubDocumentService _epubService;
  final PdfDocumentService _pdfService;

  @override
  Future<ImportedDocumentMetadata> inspect({
    required String path,
    required String displayName,
    required DocumentFormat format,
  }) async {
    final fallbackTitle = _titleFromFileName(displayName);
    switch (format) {
      case DocumentFormat.epub:
        final book = await _epubService.open(
          path,
          fallbackTitle: fallbackTitle,
        );
        return ImportedDocumentMetadata(
          title: book.title,
          author: book.author,
          language: book.language,
          description: book.description,
        );
      case DocumentFormat.pdf:
        final inspection = await _pdfService.inspect(path);
        return ImportedDocumentMetadata(
          title: fallbackTitle,
          author: 'Unknown author',
          language: 'Not set',
          description: '',
          pageCount: inspection.pageCount,
        );
    }
  }

  String _titleFromFileName(String displayName) {
    final stem = p.basenameWithoutExtension(displayName).trim();
    if (stem.isEmpty) return 'Untitled document';
    return stem
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
