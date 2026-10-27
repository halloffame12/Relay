import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/drift_reading_progress_repository.dart';
import '../data/epubx_document_service.dart';
import '../data/local_reader_content_service.dart';
import '../data/pdfx_document_service.dart';
import '../domain/epub_document.dart';
import '../domain/pdf_document.dart';
import '../domain/reader_content.dart';
import '../domain/reading_progress.dart';
import '../domain/reading_progress_repository.dart';

final readingProgressRepositoryProvider = Provider<ReadingProgressRepository>((
  ref,
) {
  return DriftReadingProgressRepository(ref.watch(appDatabaseProvider));
});

final readingProgressProvider = StreamProvider<Map<String, ReadingProgress>>((
  ref,
) {
  return ref.watch(readingProgressRepositoryProvider).watchProgress();
});

final readingProgressForProvider = Provider.family<ReadingProgress?, String>((
  ref,
  documentId,
) {
  return ref.watch(readingProgressProvider).value?[documentId];
});

final pdfDocumentServiceProvider = Provider<PdfDocumentService>((ref) {
  ref.keepAlive();
  return PdfxDocumentService();
});

final epubDocumentServiceProvider = Provider<EpubDocumentService>((ref) {
  ref.keepAlive();
  return EpubxDocumentService();
});

final readerContentServiceProvider = Provider<ReaderContentService>((ref) {
  return LocalReaderContentService(
    fileStore: ref.watch(documentFileStoreProvider),
    epubService: ref.watch(epubDocumentServiceProvider),
    pdfService: ref.watch(pdfDocumentServiceProvider),
  );
});
