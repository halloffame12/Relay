import 'dart:typed_data';

class PdfInspection {
  const PdfInspection({required this.pageCount});

  final int pageCount;
}

class PdfPageBitmap {
  const PdfPageBitmap({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

class PdfContentException implements Exception {
  const PdfContentException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class PdfDocumentHandle {
  int get pageCount;

  Future<PdfPageBitmap> renderPage(int index, {required double targetWidth});

  Future<void> close();
}

abstract interface class PdfDocumentService {
  Future<PdfDocumentHandle> open(String path);

  Future<PdfInspection> inspect(String path);
}
