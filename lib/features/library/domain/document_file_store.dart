import '../../library/domain/document.dart';

/// Result of inspecting a file before it is copied into Relay.
class DocumentProbe {
  const DocumentProbe({required this.sizeBytes, required this.sha256});

  final int sizeBytes;
  final String sha256;
}

/// Result of a successful copy into the app-managed library directory.
class StoredDocumentFile {
  const StoredDocumentFile({
    required this.storedFileName,
    required this.filePath,
    required this.sizeBytes,
    required this.sha256,
  });

  final String storedFileName;
  final String filePath;
  final int sizeBytes;
  final String sha256;
}

enum DocumentFileErrorCode {
  inaccessible,
  empty,
  tooLarge,
  invalidFormat,
  notEnoughSpace,
  copyFailed,
  cancelled,
  invalidName,
}

class DocumentFileException implements Exception {
  const DocumentFileException(this.message, {required this.code});

  final String message;
  final DocumentFileErrorCode code;

  @override
  String toString() => message;
}

/// Narrow file-system boundary used by the import, reader, and removal flows.
///
/// Widgets never touch files directly. The implementation receives the
/// app-managed library directory from the app shell so it can be replaced with
/// a temporary directory in tests.
abstract interface class DocumentFileStore {
  Future<DocumentProbe> probe(
    String sourcePath, {
    required DocumentFormat format,
    required int maxBytes,
  });

  Future<StoredDocumentFile> copyIntoLibrary({
    required String sourcePath,
    required String displayName,
    required DocumentFormat format,
    required int expectedSizeBytes,
    required String expectedSha256,
    void Function(double progress)? onProgress,
    bool Function()? isCancelled,
  });

  Future<bool> exists(String storedFileName);

  /// Resolves a validated internal filename to its absolute path.
  String pathFor(String storedFileName);

  Future<void> delete(String storedFileName);
}
