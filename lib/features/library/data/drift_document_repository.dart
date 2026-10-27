import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../../core/storage/app_database.dart';
import '../domain/document.dart';
import '../domain/document_file_store.dart';
import '../domain/document_repository.dart';

/// Drift-backed source of truth for the local document library.
class DriftDocumentRepository implements DocumentRepository {
  DriftDocumentRepository(this._database, this._fileStore);

  final AppDatabase _database;
  final DocumentFileStore _fileStore;

  @override
  Stream<List<Document>> watchDocuments() {
    final query = _database.select(_database.documents)
      ..orderBy([(t) => OrderingTerm.desc(t.addedAt)]);
    return query.watch().asyncMap(_mapRows);
  }

  @override
  Future<List<Document>> getDocuments() async {
    final query = _database.select(_database.documents)
      ..orderBy([(t) => OrderingTerm.desc(t.addedAt)]);
    return _mapRows(await query.get());
  }

  @override
  Future<Document?> findById(String id) async {
    final row = await (_database.select(
      _database.documents,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDocument(row);
  }

  @override
  Future<Document?> findBySha256(String sha256) async {
    final row = await (_database.select(
      _database.documents,
    )..where((t) => t.sha256.equals(sha256))).getSingleOrNull();
    return row == null ? null : _toDocument(row);
  }

  @override
  Future<void> addDocument(Document document) async {
    final storedFileName = document.storedFileName;
    final sha256 = document.sha256;
    if (storedFileName == null || sha256 == null) {
      throw ArgumentError(
        'A library document must have a stored file and content hash.',
      );
    }
    _fileStore.pathFor(storedFileName);

    await _database
        .into(_database.documents)
        .insert(
          DocumentsCompanion.insert(
            id: document.id,
            title: document.title,
            author: document.author,
            originalFileName: document.displayFileName,
            storedFileName: storedFileName,
            format: document.format.name,
            sizeBytes: document.sizeBytes,
            addedAt: document.addedAt,
            lastOpenedAt: Value(document.lastOpenedAt),
            sha256: sha256,
            description: Value(document.description),
            source: Value(document.source),
            language: Value(document.language),
            pageCount: Value(document.pageCount),
            coverDesign: document.coverDesign.name,
            coverPalette: document.coverPalette.name,
            isImported: Value(document.isImported),
          ),
        );
  }

  @override
  Future<void> markOpened(String id) async {
    await (_database.update(_database.documents)..where((t) => t.id.equals(id)))
        .write(DocumentsCompanion(lastOpenedAt: Value(DateTime.now())));
  }

  @override
  Future<void> updatePageCount(String id, int? pageCount) async {
    await (_database.update(_database.documents)..where((t) => t.id.equals(id)))
        .write(DocumentsCompanion(pageCount: Value(pageCount)));
  }

  @override
  Future<DocumentRemovalResult> removeDocument(String id) async {
    final row = await (_database.select(
      _database.documents,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return const DocumentRemovalResult(fileRemoved: true);

    // Delete Relay's managed copy first. If this fails, the library record
    // stays in place so the user can retry rather than losing the pointer.
    await _fileStore.delete(row.storedFileName);
    await (_database.delete(
      _database.documents,
    )..where((t) => t.id.equals(id))).go();
    return const DocumentRemovalResult(fileRemoved: true);
  }

  Future<List<Document>> _mapRows(List<DocumentRow> rows) async {
    final documents = <Document>[];
    for (final row in rows) {
      documents.add(await _toDocument(row));
    }
    return documents;
  }

  Future<Document> _toDocument(DocumentRow row) async {
    final storedFileName = row.storedFileName;
    var missing = true;
    try {
      missing =
          storedFileName.isEmpty || !await _fileStore.exists(storedFileName);
    } catch (_) {
      missing = true;
    }
    return Document(
      id: row.id,
      title: row.title,
      author: row.author,
      source: row.source,
      format: _formatFromName(row.format),
      sizeBytes: row.sizeBytes,
      addedAt: row.addedAt,
      description: row.description,
      coverDesign: _coverDesignFromName(row.coverDesign),
      coverPalette: _coverPaletteFromName(row.coverPalette),
      language: row.language,
      pageCount: row.pageCount,
      isImported: row.isImported,
      fileName: row.originalFileName,
      storedFileName: storedFileName,
      sha256: row.sha256,
      lastOpenedAt: row.lastOpenedAt,
      isMissing: missing,
    );
  }

  DocumentFormat _formatFromName(String name) {
    return DocumentFormat.values.firstWhere(
      (format) => format.name == name,
      orElse: () => DocumentFormat.pdf,
    );
  }

  CoverDesign _coverDesignFromName(String name) {
    return CoverDesign.values.firstWhere(
      (design) => design.name == name,
      orElse: () => CoverDesign.minimal,
    );
  }

  CoverPalette _coverPaletteFromName(String name) {
    return CoverPalette.values.firstWhere(
      (palette) => palette.name == name,
      orElse: () => CoverPalette.forest,
    );
  }
}

/// Deterministic palette assignment for imported files. The cover is drawn by
/// Relay, so the document identity stays recognizable without a network image.
CoverPalette paletteForDocument(String seed) {
  const palettes = CoverPalette.values;
  return palettes[seed.hashCode.abs() % palettes.length];
}

CoverDesign designForDocument(String seed) {
  const designs = CoverDesign.values;
  return designs[seed.hashCode.abs() % designs.length];
}

@visibleForTesting
String formatForStorage(DocumentFormat format) => format.name;
