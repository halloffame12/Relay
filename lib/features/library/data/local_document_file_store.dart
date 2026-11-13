import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../domain/document.dart';
import '../domain/document_file_store.dart';

/// File-system implementation backed by an app-managed directory.
///
/// The original document is never modified. A selected file is streamed into a
/// uniquely named file inside [libraryDirectory], so same-named imports cannot
/// overwrite each other.
class LocalDocumentFileStore implements DocumentFileStore {
  LocalDocumentFileStore(this.libraryDirectory);

  final Directory libraryDirectory;
  final Random _random = Random.secure();

  @override
  Future<DocumentProbe> probe(
    String sourcePath, {
    required DocumentFormat format,
    required int maxBytes,
  }) async {
    final file = File(sourcePath);
    try {
      if (!await file.exists()) {
        throw const DocumentFileException(
          'That file is no longer available. Choose it again from this device.',
          code: DocumentFileErrorCode.inaccessible,
        );
      }
      final size = await file.length();
      if (size <= 0) {
        throw const DocumentFileException(
          'The selected file is empty.',
          code: DocumentFileErrorCode.empty,
        );
      }
      if (size > maxBytes) {
        throw DocumentFileException(
          'That file is larger than the local import limit.',
          code: DocumentFileErrorCode.tooLarge,
        );
      }
      await _validateHeader(file, format);
      final digest = await _sha256(file);
      return DocumentProbe(sizeBytes: size, sha256: digest);
    } on DocumentFileException {
      rethrow;
    } on FileSystemException catch (error) {
      throw _fileException(error, 'Relay could not read that file.');
    }
  }

  @override
  Future<StoredDocumentFile> copyIntoLibrary({
    required String sourcePath,
    required String displayName,
    required DocumentFormat format,
    required int expectedSizeBytes,
    required String expectedSha256,
    void Function(double progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final source = File(sourcePath);
    await libraryDirectory.create(recursive: true);

    final storedFileName = await _uniqueStoredFileName(displayName, format);
    final destination = File(_joinChecked(storedFileName));
    final partial = File('${destination.path}.part');
    IOSink? sink;

    void ensureNotCancelled() {
      if (isCancelled?.call() ?? false) {
        throw const DocumentFileException(
          'The import was cancelled.',
          code: DocumentFileErrorCode.cancelled,
        );
      }
    }

    String copiedHash = '';
    var copiedBytes = 0;
    final digestSink = sha256.startChunkedConversion(
      ChunkedConversionSink<Digest>.withCallback((digests) {
        if (digests.isNotEmpty) copiedHash = digests.first.toString();
      }),
    );

    try {
      ensureNotCancelled();
      if (!await source.exists()) {
        throw const DocumentFileException(
          'The original file is no longer available. Choose it again.',
          code: DocumentFileErrorCode.inaccessible,
        );
      }
      if (await destination.exists()) {
        throw const DocumentFileException(
          'A file with that name already exists in Relay.',
          code: DocumentFileErrorCode.copyFailed,
        );
      }

      sink = partial.openWrite();
      await for (final chunk in source.openRead()) {
        ensureNotCancelled();
        sink.add(chunk);
        digestSink.add(chunk);
        copiedBytes += chunk.length;
        if (expectedSizeBytes > 0) {
          onProgress?.call((copiedBytes / expectedSizeBytes).clamp(0.0, 0.92));
        }
      }
      await sink.flush();
      await sink.close();
      sink = null;
      digestSink.close();

      ensureNotCancelled();

      if (copiedBytes != expectedSizeBytes || copiedHash != expectedSha256) {
        throw const DocumentFileException(
          'The file changed while it was being imported. Nothing was added.',
          code: DocumentFileErrorCode.copyFailed,
        );
      }

      // Keep the incomplete file hidden until the copy is complete. The rename
      // is within the same directory and cannot overwrite an existing entry.
      if (await destination.exists()) {
        throw const DocumentFileException(
          'A file with that name already exists in Relay.',
          code: DocumentFileErrorCode.copyFailed,
        );
      }
      await partial.rename(destination.path);
      onProgress?.call(0.95);
      return StoredDocumentFile(
        storedFileName: storedFileName,
        filePath: destination.path,
        sizeBytes: copiedBytes,
        sha256: copiedHash,
      );
    } on DocumentFileException {
      rethrow;
    } on FileSystemException catch (error) {
      throw _fileException(error, 'Relay could not copy that document.');
    } finally {
      try {
        await sink?.close();
      } catch (_) {
        // The original failure is more useful than a secondary close error.
      }
      try {
        if (await partial.exists()) await partial.delete();
      } catch (_) {
        // A partial file is harmless and can be cleaned up on a later import.
      }
    }
  }

  @override
  Future<bool> exists(String storedFileName) async {
    final file = File(pathFor(storedFileName));
    try {
      return await file.exists();
    } on FileSystemException {
      return false;
    }
  }

  @override
  String pathFor(String storedFileName) {
    if (storedFileName.isEmpty ||
        p.basename(storedFileName) != storedFileName ||
        storedFileName == '.' ||
        storedFileName == '..') {
      throw const DocumentFileException(
        'Relay blocked an invalid library file name.',
        code: DocumentFileErrorCode.invalidName,
      );
    }
    final path = _joinChecked(storedFileName);
    final root = p.normalize(libraryDirectory.absolute.path);
    final resolved = p.normalize(File(path).absolute.path);
    if (!p.isWithin(root, resolved)) {
      throw const DocumentFileException(
        'Relay blocked a file outside its library directory.',
        code: DocumentFileErrorCode.invalidName,
      );
    }
    return resolved;
  }

  @override
  Future<void> delete(String storedFileName) async {
    final file = File(pathFor(storedFileName));
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException catch (error) {
      throw _fileException(error, 'Relay could not remove that file.');
    }
  }

  String _joinChecked(String storedFileName) {
    return p.join(libraryDirectory.path, storedFileName);
  }

  Future<void> _validateHeader(File file, DocumentFormat format) async {
    final handle = await file.open();
    try {
      final header = await handle.read(16);
      final valid = switch (format) {
        DocumentFormat.pdf => _looksLikePdf(header),
        DocumentFormat.epub => _looksLikeZip(header),
      };
      if (!valid) {
        throw DocumentFileException(
          format == DocumentFormat.pdf
              ? 'That file does not look like a readable PDF.'
              : 'That file does not look like a readable EPUB.',
          code: DocumentFileErrorCode.invalidFormat,
        );
      }
    } finally {
      await handle.close();
    }
  }

  bool _looksLikePdf(List<int> bytes) {
    var start = 0;
    while (start < bytes.length &&
        (bytes[start] == 0xEF ||
            bytes[start] == 0xBB ||
            bytes[start] == 0xBF ||
            bytes[start] == 0x20 ||
            bytes[start] == 0x09 ||
            bytes[start] == 0x0A ||
            bytes[start] == 0x0D)) {
      start++;
    }
    const marker = [0x25, 0x50, 0x44, 0x46, 0x2D]; // %PDF-
    if (bytes.length - start < marker.length) return false;
    for (var i = 0; i < marker.length; i++) {
      if (bytes[start + i] != marker[i]) return false;
    }
    return true;
  }

  bool _looksLikeZip(List<int> bytes) {
    if (bytes.length < 4) return false;
    return bytes[0] == 0x50 &&
        bytes[1] == 0x4B &&
        ((bytes[2] == 0x03 && bytes[3] == 0x04) ||
            (bytes[2] == 0x05 && bytes[3] == 0x06) ||
            (bytes[2] == 0x07 && bytes[3] == 0x08));
  }

  Future<String> _sha256(File file) async {
    try {
      final digest = await sha256.bind(file.openRead()).first;
      return digest.toString();
    } on FileSystemException {
      throw const DocumentFileException(
        'Relay could not verify that file on this device.',
        code: DocumentFileErrorCode.inaccessible,
      );
    } on StateError {
      throw const DocumentFileException(
        'That file changed while Relay was checking it. Choose it again.',
        code: DocumentFileErrorCode.inaccessible,
      );
    }
  }

  Future<String> _uniqueStoredFileName(
    String displayName,
    DocumentFormat format,
  ) async {
    final stem = _safeStem(displayName);
    for (var attempt = 0; attempt < 12; attempt++) {
      final candidate =
          '${DateTime.now().microsecondsSinceEpoch}-${_randomHex(6)}-$stem.'
          '${format.fileExtension}';
      if (!await File(_joinChecked(candidate)).exists()) return candidate;
    }
    throw const DocumentFileException(
      'Relay could not create a unique name for that document.',
      code: DocumentFileErrorCode.copyFailed,
    );
  }

  String _safeStem(String displayName) {
    final base = p.basenameWithoutExtension(displayName).toLowerCase();
    final slug = base
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (slug.isEmpty) return 'document';
    return slug.length <= 48 ? slug : slug.substring(0, 48);
  }

  String _randomHex(int bytes) {
    final buffer = StringBuffer();
    for (var i = 0; i < bytes; i++) {
      buffer.write(_random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  DocumentFileException _fileException(
    FileSystemException error,
    String fallback,
  ) {
    final code = error.osError?.errorCode;
    final message = error.osError?.message ?? error.message;
    if (code == 28 || message.toLowerCase().contains('no space left')) {
      return const DocumentFileException(
        'There is not enough free space to copy this document. '
        'Free some space and try again.',
        code: DocumentFileErrorCode.notEnoughSpace,
      );
    }
    if (code == 13 || message.toLowerCase().contains('permission denied')) {
      return const DocumentFileException(
        'Relay does not have access to that file. Choose it again from the '
        'system file picker.',
        code: DocumentFileErrorCode.inaccessible,
      );
    }
    return DocumentFileException(
      fallback,
      code: DocumentFileErrorCode.copyFailed,
    );
  }
}
