import '../domain/document.dart';

/// Outcome of removing a document. No document is ever removed from an
/// external source provider by Relay; only the app-managed copy is deleted.
class DocumentRemovalResult {
  const DocumentRemovalResult({required this.fileRemoved});

  final bool fileRemoved;
}

abstract interface class DocumentRepository {
  Stream<List<Document>> watchDocuments();

  Future<List<Document>> getDocuments();

  Future<Document?> findById(String id);

  Future<Document?> findBySha256(String sha256);

  Future<void> addDocument(Document document);

  Future<void> markOpened(String id);

  Future<void> updatePageCount(String id, int? pageCount);

  Future<DocumentRemovalResult> removeDocument(String id);
}
