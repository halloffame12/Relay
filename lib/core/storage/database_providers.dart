import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'app_database.dart';
import 'storage_providers.dart';

/// One SQLite database per app data directory. The directory is provided by
/// `main()` on device and by a temporary directory in tests.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  ref.keepAlive();
  final directory = ref.watch(appDataDirectoryProvider);
  directory.createSync(recursive: true);
  final database = AppDatabase.open(
    File(p.join(directory.path, 'relay.sqlite')),
  );
  ref.onDispose(() {
    unawaited(database.close());
  });
  return database;
});
