import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'app_database.g.dart';

/// One row per document Relay manages on this device.
///
/// Only the internal [storedFileName] is persisted. The absolute path is
/// resolved at runtime from the app-managed library directory so moving the
/// app's data directory does not invalidate the library.
@DataClassName('DocumentRow')
class Documents extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get author => text()();
  TextColumn get originalFileName => text()();
  TextColumn get storedFileName => text()();
  TextColumn get format => text()();
  IntColumn get sizeBytes => integer()();
  DateTimeColumn get addedAt => dateTime()();
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();
  TextColumn get sha256 => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get source => text().withDefault(const Constant('Imported'))();
  TextColumn get language => text().withDefault(const Constant('Not set'))();
  IntColumn get pageCount => integer().nullable()();
  TextColumn get coverDesign => text()();
  TextColumn get coverPalette => text()();
  BoolColumn get isImported => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {sha256},
  ];
}

/// Reader position for a document. Keeping this beside the document metadata
/// makes opening and restoring a document a single local transaction.
@DataClassName('ReadingProgressRow')
class ReadingProgressEntries extends Table {
  TextColumn get documentId =>
      text().references(Documents, #id, onDelete: KeyAction.cascade)();
  RealColumn get fraction => real().withDefault(const Constant(0))();
  IntColumn get locationIndex => integer().withDefault(const Constant(0))();
  RealColumn get locationOffset => real().withDefault(const Constant(0))();
  TextColumn get locationRef => text().nullable()();
  DateTimeColumn get lastReadAt => dateTime().nullable()();
  TextColumn get bookmarks => text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {documentId};
}

/// A real local-network transfer record. Terminal rows stay as history until
/// the user clears them; files are never referenced by an absolute path.
@DataClassName('TransferRow')
class TransferEntries extends Table {
  TextColumn get id => text()();
  TextColumn get direction => text()();

  /// Local library document id, when it still exists. This is intentionally
  /// not a foreign key so finished transfer history remains readable after a
  /// document is removed.
  TextColumn get documentId => text().nullable()();
  TextColumn get documentTitle => text()();
  TextColumn get fileTypeLabel => text()();
  IntColumn get sizeBytes => integer()();
  IntColumn get transferredBytes => integer().withDefault(const Constant(0))();
  TextColumn get state => text()();
  TextColumn get peerName => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get failureReason => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get tempFileName => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Documents, ReadingProgressEntries, TransferEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  factory AppDatabase.open(File file) {
    return AppDatabase(NativeDatabase.createInBackground(file));
  }

  /// Used by tests with an in-memory or otherwise isolated executor.
  factory AppDatabase.forTesting(QueryExecutor executor) {
    return AppDatabase(executor);
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (migrator) async {
        await migrator.createAll();
      },
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          // Additive migration. Existing documents, reading progress, and
          // app-managed files are left untouched.
          await migrator.createTable(transferEntries);
        }
      },
      beforeOpen: (details) async {
        // Drift does not enable SQLite foreign keys by default. Cascading
        // reading progress when a document is removed depends on this pragma.
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}
