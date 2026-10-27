import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/providers/app_providers.dart';
import 'core/storage/storage_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final supportDirectory = await getApplicationSupportDirectory();
  final libraryDirectory = Directory(p.join(supportDirectory.path, 'library'));
  await libraryDirectory.create(recursive: true);
  await _removeIncompleteImports(libraryDirectory);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        appDataDirectoryProvider.overrideWithValue(supportDirectory),
        documentLibraryDirectoryProvider.overrideWithValue(libraryDirectory),
      ],
      child: const RelayApp(),
    ),
  );
}

/// Interrupted imports leave a hidden `.part` file. It is never a library
/// document and can be safely removed on the next launch.
Future<void> _removeIncompleteImports(Directory directory) async {
  try {
    await for (final entity in directory.list()) {
      if (entity is File && entity.path.endsWith('.part')) {
        try {
          await entity.delete();
        } catch (_) {
          // A retry on the next launch is harmless.
        }
      }
    }
  } on FileSystemException {
    // The import flow will surface a useful error if storage is unavailable.
  }
}
