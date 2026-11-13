import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../../../app/theme/app_tokens.dart';
import '../../../core/utils/untrusted_text.dart';
import '../../library/domain/document.dart';
import '../../library/domain/document_file_store.dart';
import '../../library/domain/document_repository.dart';
import '../domain/document_import_service.dart';
import 'document_metadata_service.dart';

/// Imports a device file through the Android system picker into Relay's
/// app-managed library. No broad storage permission is requested.
class FilePickerDocumentImportService implements DocumentImportService {
  FilePickerDocumentImportService({
    required DocumentRepository repository,
    required DocumentFileStore fileStore,
    required DocumentMetadataService metadataService,
  }) : _repository = repository,
       _fileStore = fileStore,
       _metadataService = metadataService;

  final DocumentRepository _repository;
  final DocumentFileStore _fileStore;
  final DocumentMetadataService _metadataService;
  final Random _random = Random.secure();

  @override
  Future<PickedImportFile?> pickFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: AppConstants.supportedExtensions,
        dialogTitle: 'Choose a PDF or EPUB',
      );
      if (files.isEmpty) return null;
      final selected = files.first;
      final path = selected.path;
      if (path == null || path.isEmpty) {
        throw const ImportPickerException(
          'Relay could not access that file. Choose it again from this device.',
        );
      }
      final displayName = _cleanDisplayName(selected.name);
      final format = _formatFor(displayName, selected.extension);
      final probe = await _fileStore.probe(
        path,
        format: format,
        maxBytes: AppConstants.maxImportBytes,
      );
      return PickedImportFile(
        name: displayName,
        path: path,
        sizeBytes: probe.sizeBytes,
        format: format,
        sha256: probe.sha256,
      );
    } on ImportPickerException {
      rethrow;
    } on DocumentFileException catch (error) {
      throw ImportPickerException(error.message);
    } catch (_) {
      throw const ImportPickerException(
        'The file picker could not be opened. Try again.',
      );
    }
  }

  @override
  Future<Document?> findDuplicate(PickedImportFile file) {
    return _repository.findBySha256(file.sha256);
  }

  @override
  Future<ImportResult> importFile(
    PickedImportFile file, {
    required void Function(double progress) onProgress,
    ImportCancellationToken? cancellation,
  }) async {
    bool isCancelled() => cancellation?.isCancelled ?? false;
    StoredDocumentFile? stored;
    var committed = false;

    void checkCancelled() {
      if (isCancelled()) throw const ImportCancelledException();
    }

    try {
      checkCancelled();
      final duplicate = await _repository.findBySha256(file.sha256);
      if (duplicate != null) return ImportResult.duplicate(duplicate);

      onProgress(0.04);
      checkCancelled();
      stored = await _fileStore.copyIntoLibrary(
        sourcePath: file.path,
        displayName: file.name,
        format: file.format,
        expectedSizeBytes: file.sizeBytes,
        expectedSha256: file.sha256,
        isCancelled: isCancelled,
        onProgress: (value) => onProgress(0.05 + value * 0.60),
      );
      checkCancelled();

      onProgress(0.72);
      final metadata = await _metadataService.inspect(
        path: stored.filePath,
        displayName: file.name,
        format: file.format,
      );
      checkCancelled();

      onProgress(0.9);
      final metadataTitle = UntrustedText.clean(
        metadata.title,
        maxLength: UntrustedText.maxTitleLength,
      );
      final title = await _uniqueTitle(
        metadataTitle.isEmpty ? _titleFromFileName(file.name) : metadataTitle,
      );
      final author = UntrustedText.clean(
        metadata.author,
        maxLength: UntrustedText.maxAuthorLength,
      );
      final description = UntrustedText.clean(
        metadata.description,
        maxLength: UntrustedText.maxDescriptionLength,
      );
      final language = UntrustedText.language(metadata.language);
      final now = DateTime.now();
      final document = Document(
        id: _newId(),
        title: title,
        author: author.isEmpty ? 'Unknown author' : author,
        source: file.sourceLabel,
        format: file.format,
        sizeBytes: stored.sizeBytes,
        addedAt: now,
        description: description.isEmpty
            ? file.fallbackDescription
            : description,
        coverDesign: _coverDesign(file.sha256),
        coverPalette: _coverPalette(file.sha256),
        language: language.isEmpty ? 'Not set' : language,
        pageCount: metadata.pageCount,
        isImported: true,
        fileName: file.name,
        storedFileName: stored.storedFileName,
        sha256: file.sha256,
        isMissing: false,
      );

      checkCancelled();
      try {
        await _repository.addDocument(document);
        committed = true;
      } catch (_) {
        // The copied file is cleaned up below. Never leave a library record
        // pointing at a file whose database commit failed.
        return ImportResult.failure(
          'Relay could not finish adding this document to your library. '
          'The copied file was removed.',
        );
      }
      onProgress(1);
      return ImportResult.success(document);
    } on ImportCancelledException {
      rethrow;
    } on DocumentFileException catch (error) {
      if (error.code == DocumentFileErrorCode.cancelled) {
        throw const ImportCancelledException();
      }
      return ImportResult.failure(error.message);
    } catch (_) {
      return ImportResult.failure(
        'The import stopped unexpectedly. Your original file was not changed.',
      );
    } finally {
      if (!committed && stored != null) {
        try {
          await _fileStore.delete(stored.storedFileName);
        } catch (_) {
          // Best-effort cleanup; a failed cleanup must not mask the import
          // error shown to the reader.
        }
      }
    }
  }

  DocumentFormat _formatFor(String name, String? pickerExtension) {
    var extension = p.extension(name).toLowerCase();
    if (extension.isEmpty && pickerExtension != null) {
      extension = '.${pickerExtension.toLowerCase()}';
    }
    return switch (extension) {
      '.pdf' => DocumentFormat.pdf,
      '.epub' => DocumentFormat.epub,
      _ => throw const ImportPickerException(
        'Relay supports PDF and EPUB files only.',
      ),
    };
  }

  String _cleanDisplayName(String raw) {
    var name = raw
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
        .replaceAll(RegExp(r'[\\/]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (name.isEmpty) return 'Untitled document';
    if (name.length > 180) {
      final extension = p.extension(name);
      name = name.substring(0, 180 - extension.length) + extension;
    }
    return name;
  }

  String _titleFromFileName(String displayName) {
    final stem = p.basenameWithoutExtension(displayName).trim();
    if (stem.isEmpty) return 'Untitled document';
    final title = UntrustedText.clean(
      stem.replaceAll(RegExp(r'[_-]+'), ' '),
      maxLength: UntrustedText.maxTitleLength,
    );
    return title.isEmpty ? 'Untitled document' : title;
  }

  Future<String> _uniqueTitle(String title) async {
    final documents = await _repository.getDocuments();
    final wanted = title.trim().isEmpty ? 'Untitled document' : title.trim();
    final lower = wanted.toLowerCase();
    final existing = documents.map((doc) => doc.title.toLowerCase()).toSet();
    if (!existing.contains(lower)) return wanted;
    var suffix = 2;
    while (existing.contains('$lower ($suffix)')) {
      suffix++;
    }
    return '$wanted ($suffix)';
  }

  String _newId() {
    final buffer = StringBuffer('doc-');
    for (var i = 0; i < 8; i++) {
      buffer.write(_random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  CoverDesign _coverDesign(String seed) {
    return CoverDesign.values[seed.hashCode.abs() % CoverDesign.values.length];
  }

  CoverPalette _coverPalette(String seed) {
    return CoverPalette.values[seed.hashCode.abs() %
        CoverPalette.values.length];
  }
}
