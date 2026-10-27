import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';
import '../../library/application/library_providers.dart';
import '../../reader/application/reading_providers.dart';
import '../data/document_metadata_service.dart';
import '../data/file_picker_document_import_service.dart';
import '../domain/document_import_service.dart';

final documentMetadataServiceProvider = Provider<DocumentMetadataService>((
  ref,
) {
  return LocalDocumentMetadataService(
    epubService: ref.watch(epubDocumentServiceProvider),
    pdfService: ref.watch(pdfDocumentServiceProvider),
  );
});

final documentImportServiceProvider = Provider<DocumentImportService>((ref) {
  return FilePickerDocumentImportService(
    repository: ref.watch(documentRepositoryProvider),
    fileStore: ref.watch(documentFileStoreProvider),
    metadataService: ref.watch(documentMetadataServiceProvider),
  );
});
