import '../../library/domain/document.dart';

class PickedImportFile {
  const PickedImportFile({
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.format,
    required this.sha256,
    this.sourceLabel = 'Imported from this device',
    this.fallbackDescription =
        'Imported from a local file. The original remains where it is.',
  });

  final String name;
  final String path;
  final int sizeBytes;
  final DocumentFormat format;
  final String sha256;
  final String sourceLabel;
  final String fallbackDescription;
}

enum ImportOutcome { success, duplicate, failure }

class ImportResult {
  const ImportResult._({
    required this.outcome,
    this.document,
    this.existingDocument,
    this.message,
  });

  factory ImportResult.success(Document document) =>
      ImportResult._(outcome: ImportOutcome.success, document: document);

  factory ImportResult.duplicate(Document existing) => ImportResult._(
    outcome: ImportOutcome.duplicate,
    existingDocument: existing,
    message: '“${existing.title}” is already in your library.',
  );

  factory ImportResult.failure(String message) =>
      ImportResult._(outcome: ImportOutcome.failure, message: message);

  final ImportOutcome outcome;
  final Document? document;
  final Document? existingDocument;
  final String? message;
}

class ImportPickerException implements Exception {
  const ImportPickerException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ImportCancelledException implements Exception {
  const ImportCancelledException();
}

class ImportCancellationToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() {
    _cancelled = true;
  }
}

abstract interface class DocumentImportService {
  Future<PickedImportFile?> pickFile();

  Future<Document?> findDuplicate(PickedImportFile file);

  Future<ImportResult> importFile(
    PickedImportFile file, {
    required void Function(double progress) onProgress,
    ImportCancellationToken? cancellation,
  });
}
