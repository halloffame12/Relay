import 'dart:async';
import 'dart:io';

import 'package:pdfx/pdfx.dart' as pdfx;

import '../domain/pdf_document.dart';

/// Production PDF renderer backed by the platform PDF engine via `pdfx`.
class PdfxDocumentService implements PdfDocumentService {
  @override
  Future<PdfDocumentHandle> open(String path) async {
    try {
      final document = await pdfx.PdfDocument.openFile(path);
      if (document.pagesCount <= 0) {
        await document.close();
        throw const PdfContentException('This PDF has no readable pages.');
      }
      return _PdfxHandle(document);
    } on PdfContentException {
      rethrow;
    } on FileSystemException {
      throw const PdfContentException('Relay could not read this PDF file.');
    } catch (_) {
      throw const PdfContentException(
        'This file could not be opened as a PDF. It may be damaged or '
        'password-protected.',
      );
    }
  }

  @override
  Future<PdfInspection> inspect(String path) async {
    final handle = await open(path);
    try {
      return PdfInspection(pageCount: handle.pageCount);
    } finally {
      await handle.close();
    }
  }
}

class _PdfxHandle implements PdfDocumentHandle {
  _PdfxHandle(this._document);

  final pdfx.PdfDocument _document;
  final Map<int, PdfPageBitmap> _cache = {};
  Future<void> _queue = Future<void>.value();
  bool _closed = false;

  @override
  int get pageCount => _document.pagesCount;

  @override
  Future<PdfPageBitmap> renderPage(int index, {required double targetWidth}) {
    return _serialized(() async {
      if (_closed) {
        throw const PdfContentException('The PDF was closed.');
      }
      final cached = _cache.remove(index);
      if (cached != null) {
        _cache[index] = cached;
        return cached;
      }
      if (index < 0 || index >= pageCount) {
        throw const PdfContentException('That page is outside this PDF.');
      }

      pdfx.PdfPage? page;
      try {
        page = await _document.getPage(index + 1);
        final sourceWidth = page.width <= 0 ? 595.0 : page.width;
        final sourceHeight = page.height <= 0 ? 842.0 : page.height;
        final width = targetWidth.clamp(480.0, 2000.0);
        final height = (width * sourceHeight / sourceWidth).clamp(
          480.0,
          3000.0,
        );
        final image = await page.render(
          width: width,
          height: height,
          format: pdfx.PdfPageImageFormat.jpeg,
          quality: 88,
          backgroundColor: '#FFFFFF',
        );
        if (image == null || image.bytes.isEmpty) {
          throw const PdfContentException(
            'This page could not be rendered. Try reopening the document.',
          );
        }
        final bitmap = PdfPageBitmap(
          bytes: image.bytes,
          width: image.width ?? width.round(),
          height: image.height ?? height.round(),
        );
        _cache[index] = bitmap;
        while (_cache.length > 3) {
          _cache.remove(_cache.keys.first);
        }
        return bitmap;
      } on PdfContentException {
        rethrow;
      } catch (_) {
        throw const PdfContentException(
          'This page could not be rendered. The PDF may be damaged.',
        );
      } finally {
        if (page != null && !page.isClosed) {
          try {
            await page.close();
          } catch (_) {
            // The document may already have been closed during disposal.
          }
        }
      }
    });
  }

  @override
  Future<void> close() {
    return _serialized(() async {
      if (_closed) return;
      _closed = true;
      _cache.clear();
      try {
        await _document.close();
      } catch (_) {
        // Closing is best-effort during navigation away from the reader.
      }
    });
  }

  Future<T> _serialized<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _queue = _queue.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}
