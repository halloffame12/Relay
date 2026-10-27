import 'package:path/path.dart' as p;

import '../../library/domain/document.dart';

class TransferValidationException implements Exception {
  const TransferValidationException(this.message, {this.code = 'invalid'});

  final String message;
  final String code;

  @override
  String toString() => message;
}

/// The only document information a peer is allowed to send before the file
/// bytes. Every field is validated before it reaches a file or the database.
class TransferManifest {
  const TransferManifest._({
    required this.fileName,
    required this.title,
    required this.format,
    required this.sizeBytes,
    required this.sha256,
  });

  final String fileName;
  final String title;
  final DocumentFormat format;
  final int sizeBytes;
  final String sha256;

  factory TransferManifest.validated({
    required String fileName,
    required String title,
    required String format,
    required int sizeBytes,
    required String sha256,
    required int maxBytes,
  }) {
    final cleanName = fileName.trim();
    if (cleanName.isEmpty || cleanName.length > 180) {
      throw const TransferValidationException(
        'The document name is missing or too long.',
        code: 'invalid_name',
      );
    }
    if (cleanName == '.' ||
        cleanName == '..' ||
        cleanName.contains('/') ||
        cleanName.contains('\\') ||
        p.basename(cleanName) != cleanName ||
        RegExp(r'[\x00-\x1F\x7F]').hasMatch(cleanName)) {
      throw const TransferValidationException(
        'The document name contains an unsafe path.',
        code: 'unsafe_name',
      );
    }

    final parsedFormat = switch (format.trim().toLowerCase()) {
      'pdf' => DocumentFormat.pdf,
      'epub' => DocumentFormat.epub,
      _ => throw const TransferValidationException(
        'Relay accepts PDF and EPUB documents only.',
        code: 'unsupported_format',
      ),
    };
    final extension = p.extension(cleanName).toLowerCase();
    final expectedExtension = '.${parsedFormat.fileExtension}';
    if (extension != expectedExtension) {
      throw const TransferValidationException(
        'The document extension does not match its declared format.',
        code: 'format_mismatch',
      );
    }

    if (sizeBytes <= 0) {
      throw const TransferValidationException(
        'The declared document is empty.',
        code: 'empty_file',
      );
    }
    if (sizeBytes > maxBytes) {
      throw TransferValidationException(
        'The document is larger than the $maxBytes byte transfer limit.',
        code: 'file_too_large',
      );
    }

    final cleanHash = sha256.trim().toLowerCase();
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(cleanHash)) {
      throw const TransferValidationException(
        'The document checksum is invalid.',
        code: 'invalid_checksum',
      );
    }

    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty ||
        cleanTitle.length > 200 ||
        RegExp(r'[\x00-\x1F\x7F]').hasMatch(cleanTitle)) {
      throw const TransferValidationException(
        'The document title is invalid.',
        code: 'invalid_title',
      );
    }

    return TransferManifest._(
      fileName: cleanName,
      title: cleanTitle,
      format: parsedFormat,
      sizeBytes: sizeBytes,
      sha256: cleanHash,
    );
  }

  Map<String, Object?> toJson() => {
    'fileName': fileName,
    'title': title,
    'format': format.name,
    'sizeBytes': sizeBytes,
    'sha256': sha256,
  };

  factory TransferManifest.fromJson(
    Map<String, Object?> json, {
    required int maxBytes,
  }) {
    final fileName = json['fileName'];
    final title = json['title'];
    final format = json['format'];
    final sizeBytes = json['sizeBytes'];
    final sha256 = json['sha256'];
    if (json.keys.any(
      (key) => !const {
        'fileName',
        'title',
        'format',
        'sizeBytes',
        'sha256',
      }.contains(key),
    )) {
      throw const TransferValidationException(
        'The document manifest contains an unsupported field.',
        code: 'invalid_manifest',
      );
    }
    if (fileName is! String ||
        title is! String ||
        format is! String ||
        sizeBytes is! int ||
        sha256 is! String) {
      throw const TransferValidationException(
        'The document manifest is incomplete.',
        code: 'invalid_manifest',
      );
    }
    return TransferManifest.validated(
      fileName: fileName,
      title: title,
      format: format,
      sizeBytes: sizeBytes,
      sha256: sha256,
      maxBytes: maxBytes,
    );
  }
}
