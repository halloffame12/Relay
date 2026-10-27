import '../../library/domain/document.dart';
import 'epub_document.dart';
import 'pdf_document.dart';

sealed class ReaderContent {
  const ReaderContent();
}

final class PdfReaderContent extends ReaderContent {
  const PdfReaderContent(this.document);

  final PdfDocumentHandle document;
}

final class EpubReaderContent extends ReaderContent {
  const EpubReaderContent(this.document);

  final EpubDocument document;
}

class ReaderContentException implements Exception {
  const ReaderContentException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class ReaderContentService {
  Future<ReaderContent> open(Document document);
}
