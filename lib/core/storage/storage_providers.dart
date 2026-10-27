import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/library/data/local_document_file_store.dart';
import '../../features/library/domain/document_file_store.dart';

/// The app-managed data directory, injected in `main()` (and test overrides).
///
/// The database and the document library both live beneath this directory.
final appDataDirectoryProvider = Provider<Directory>((ref) {
  throw UnimplementedError('App data directory must be provided at startup.');
});

/// The directory that holds document files copied into Relay.
final documentLibraryDirectoryProvider = Provider<Directory>((ref) {
  throw UnimplementedError(
    'Document library directory must be provided at startup.',
  );
});

/// File-system boundary for the local library. The directory is app-managed,
/// not the user's original folder, so Relay can safely remove its own copy.
final documentFileStoreProvider = Provider<DocumentFileStore>((ref) {
  final directory = ref.watch(documentLibraryDirectoryProvider);
  directory.createSync(recursive: true);
  return LocalDocumentFileStore(directory);
});
