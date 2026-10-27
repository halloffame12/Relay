import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:relay/core/storage/app_database.dart';
import 'package:relay/features/transfers/data/drift_transfer_repository.dart';
import 'package:relay/features/transfers/domain/transfer_repository.dart';
import 'package:relay/features/transfers/domain/transfer_task.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('schema version 1 migrates additively to version 2 and preserves '
      'documents and reading progress', () async {
    final directory = await Directory.systemTemp.createTemp('relay-migration-');
    final file = File(p.join(directory.path, 'relay.sqlite'));
    addTearDown(() async {
      try {
        await directory.delete(recursive: true);
      } catch (_) {}
    });

    final raw = sqlite.sqlite3.open(file.path);
    raw
      ..execute('''
        CREATE TABLE documents (
          id TEXT NOT NULL PRIMARY KEY,
          title TEXT NOT NULL,
          author TEXT NOT NULL,
          original_file_name TEXT NOT NULL,
          stored_file_name TEXT NOT NULL,
          format TEXT NOT NULL,
          size_bytes INTEGER NOT NULL,
          added_at INTEGER NOT NULL,
          last_opened_at INTEGER NULL,
          sha256 TEXT NOT NULL,
          description TEXT NOT NULL DEFAULT '',
          source TEXT NOT NULL DEFAULT 'Imported',
          language TEXT NOT NULL DEFAULT 'Not set',
          page_count INTEGER NULL,
          cover_design TEXT NOT NULL,
          cover_palette TEXT NOT NULL,
          is_imported INTEGER NOT NULL DEFAULT 1,
          UNIQUE (sha256)
        )
      ''')
      ..execute('''
        CREATE TABLE reading_progress_entries (
          document_id TEXT NOT NULL PRIMARY KEY
            REFERENCES documents (id) ON DELETE CASCADE,
          fraction REAL NOT NULL DEFAULT 0,
          location_index INTEGER NOT NULL DEFAULT 0,
          location_offset REAL NOT NULL DEFAULT 0,
          location_ref TEXT NULL,
          last_read_at INTEGER NULL,
          bookmarks TEXT NOT NULL DEFAULT '[]'
        )
      ''')
      ..execute(
        "INSERT INTO documents (id, title, author, original_file_name, "
        "stored_file_name, format, size_bytes, added_at, sha256, "
        "cover_design, cover_palette) VALUES ('doc-1', 'Existing document', "
        "'Author', 'existing.pdf', 'existing-1234.pdf', 'pdf', 42, "
        "1700000000, 'a' || printf('%062d', 0), 'bands', 'forest')",
      )
      ..execute(
        "INSERT INTO reading_progress_entries (document_id, fraction, "
        "location_index, location_offset, bookmarks) VALUES "
        "('doc-1', 0.5, 3, 0.25, '[]')",
      )
      ..execute('PRAGMA user_version = 1');
    raw.close();

    final database = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(database.close);

    final documents = await database.select(database.documents).get();
    expect(documents, hasLength(1));
    expect(documents.single.id, 'doc-1');
    expect(documents.single.title, 'Existing document');

    final progress = await database
        .select(database.readingProgressEntries)
        .get();
    expect(progress, hasLength(1));
    expect(progress.single.documentId, 'doc-1');
    expect(progress.single.fraction, 0.5);

    final version = await database
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(version.data['user_version'], 2);

    final repository = DriftTransferRepository(database);
    await repository.create(
      TransferDraft(
        id: 'tx-migrated',
        direction: TransferDirection.send,
        documentId: 'doc-1',
        documentTitle: 'Existing document',
        fileTypeLabel: 'PDF',
        sizeBytes: 42,
        peerName: 'Relay device',
        status: TransferStatus.connecting,
        createdAt: DateTime(2026),
      ),
    );
    expect(await repository.findById('tx-migrated'), isNotNull);
  });
}
