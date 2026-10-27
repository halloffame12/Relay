import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/storage/app_database.dart';
import '../domain/reading_progress.dart';
import '../domain/reading_progress_repository.dart';

/// Durable reading positions backed by the same local SQLite file as the
/// library. Progress is removed with its document by a foreign-key cascade.
class DriftReadingProgressRepository implements ReadingProgressRepository {
  DriftReadingProgressRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<Map<String, ReadingProgress>> watchProgress() {
    return _database.select(_database.readingProgressEntries).watch().map((
      rows,
    ) {
      return Map<String, ReadingProgress>.unmodifiable({
        for (final row in rows) row.documentId: _toProgress(row),
      });
    });
  }

  @override
  Future<void> saveProgress(ReadingProgress progress) async {
    await _database
        .into(_database.readingProgressEntries)
        .insertOnConflictUpdate(
          ReadingProgressEntriesCompanion.insert(
            documentId: progress.documentId,
            fraction: Value(progress.fraction.clamp(0.0, 1.0)),
            locationIndex: Value(
              progress.locationIndex < 0 ? 0 : progress.locationIndex,
            ),
            locationOffset: Value(progress.locationOffset.clamp(0.0, 1.0)),
            locationRef: Value(progress.locationRef),
            lastReadAt: Value(progress.lastReadAt ?? DateTime.now()),
            bookmarks: Value(_encodeBookmarks(progress.bookmarks)),
          ),
        );
  }

  @override
  Future<void> clearAll() async {
    await _database.delete(_database.readingProgressEntries).go();
  }

  ReadingProgress _toProgress(ReadingProgressRow row) {
    return ReadingProgress(
      documentId: row.documentId,
      fraction: row.fraction,
      locationIndex: row.locationIndex,
      locationOffset: row.locationOffset,
      locationRef: row.locationRef,
      lastReadAt: row.lastReadAt,
      bookmarks: _decodeBookmarks(row.bookmarks),
    );
  }

  String _encodeBookmarks(Set<int> bookmarks) {
    final values = bookmarks.where((value) => value >= 0).toList()..sort();
    return jsonEncode(values);
  }

  Set<int> _decodeBookmarks(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<num>().map((value) => value.toInt()).toSet();
      }
    } on FormatException {
      // Corrupt bookmark JSON should not make the rest of the library fail.
    }
    return const {};
  }
}
