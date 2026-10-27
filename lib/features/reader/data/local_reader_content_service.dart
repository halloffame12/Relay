import '../../library/domain/document.dart';
import '../../library/domain/document_file_store.dart';
import '../domain/epub_document.dart';
import '../domain/pdf_document.dart';
import '../domain/reader_content.dart';

/// Opens a document's Relay-managed copy and returns the format-specific
/// reading model. Paths and file-system access stay out of presentation code.
class LocalReaderContentService implements ReaderContentService {
  LocalReaderContentService({
    required DocumentFileStore fileStore,
    required EpubDocumentService epubService,
    required PdfDocumentService pdfService,
  }) : _fileStore = fileStore,
       _epubService = epubService,
       _pdfService = pdfService;

  final DocumentFileStore _fileStore;
  final EpubDocumentService _epubService;
  final PdfDocumentService _pdfService;

  @override
  Future<ReaderContent> open(Document document) async {
    final storedFileName = document.storedFileName;
    if (storedFileName == null) {
      throw const ReaderContentException(
        'This document is not stored on this device.',
      );
    }
    try {
      if (!await _fileStore.exists(storedFileName)) {
        throw const ReaderContentException(
          'The document file is missing from this device. It may have been '
          'moved or removed outside Relay.',
        );
      }
      final path = _fileStore.pathFor(storedFileName);
      return switch (document.format) {
        DocumentFormat.pdf => PdfReaderContent(await _pdfService.open(path)),
        DocumentFormat.epub => EpubReaderContent(
          await _epubService.open(path, fallbackTitle: document.title),
        ),
      };
    } on ReaderContentException {
      rethrow;
    } on PdfContentException catch (error) {
      throw ReaderContentException(error.message);
    } on EpubFormatException catch (error) {
      throw ReaderContentException(error.message);
    } on DocumentFileException catch (error) {
      throw ReaderContentException(error.message);
    } catch (_) {
      throw const ReaderContentException(
        'Relay could not open this document. The file may be damaged.',
      );
    }
  }
}
