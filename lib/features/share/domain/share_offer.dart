import '../../transfers/domain/transfer_manifest.dart';

/// Bounds for one share batch. They are enforced on both devices before any
/// bytes are written so a peer cannot fill the receiver's storage with a
/// manifest alone.
const int shareMaxFilesPerBatch = 20;
const int shareMaxBatchBytes = 200 * 1024 * 1024;

class ShareOfferException implements Exception {
  const ShareOfferException(this.message, {this.code = 'invalid_offer'});

  final String message;
  final String code;

  @override
  String toString() => message;
}

/// The validated, ordered list of files the sender wants to transfer.
final class ShareOffer {
  const ShareOffer._({required this.batchId, required this.files});

  final String batchId;
  final List<TransferManifest> files;

  int get totalBytes =>
      files.fold<int>(0, (total, file) => total + file.sizeBytes);

  int get fileCount => files.length;

  factory ShareOffer.validated({
    required String batchId,
    required List<TransferManifest> files,
    int maxBatchBytes = shareMaxBatchBytes,
  }) {
    if (!RegExp(r'^[A-Za-z0-9_-]{8,32}$').hasMatch(batchId)) {
      throw const ShareOfferException(
        'The transfer batch identifier is invalid.',
        code: 'invalid_batch',
      );
    }
    if (files.isEmpty) {
      throw const ShareOfferException(
        'The sender did not offer any files.',
        code: 'empty_offer',
      );
    }
    if (files.length > shareMaxFilesPerBatch) {
      throw ShareOfferException(
        'The sender offered more than $shareMaxFilesPerBatch files at once.',
        code: 'too_many_files',
      );
    }
    var total = 0;
    final names = <String>{};
    for (final file in files) {
      total += file.sizeBytes;
      final key = file.fileName.toLowerCase();
      if (!names.add(key)) {
        throw const ShareOfferException(
          'The sender offered two files with the same name.',
          code: 'duplicate_file_name',
        );
      }
    }
    if (total > maxBatchBytes) {
      throw const ShareOfferException(
        'This batch is larger than the Relay transfer limit.',
        code: 'batch_too_large',
      );
    }
    return ShareOffer._(
      batchId: batchId,
      files: List<TransferManifest>.unmodifiable(files),
    );
  }

  Map<String, Object?> toJson() => {
    'batchId': batchId,
    'files': [for (final file in files) file.toJson()],
  };

  factory ShareOffer.fromJson(
    Map<String, Object?> json, {
    int maxBatchBytes = shareMaxBatchBytes,
    int maxDocumentBytes = 100 * 1024 * 1024,
  }) {
    const allowed = {'batchId', 'files'};
    if (json.keys.any((key) => !allowed.contains(key))) {
      throw const ShareOfferException(
        'The transfer offer contains an unsupported field.',
        code: 'invalid_offer',
      );
    }
    final batchId = json['batchId'];
    final rawFiles = json['files'];
    if (batchId is! String || rawFiles is! List) {
      throw const ShareOfferException(
        'The transfer offer is incomplete.',
        code: 'invalid_offer',
      );
    }
    if (rawFiles.length > shareMaxFilesPerBatch) {
      throw ShareOfferException(
        'The sender offered more than $shareMaxFilesPerBatch files at once.',
        code: 'too_many_files',
      );
    }
    final files = <TransferManifest>[];
    for (final raw in rawFiles) {
      if (raw is! Map) {
        throw const ShareOfferException(
          'The transfer offer contains an invalid file entry.',
          code: 'invalid_offer',
        );
      }
      try {
        files.add(
          TransferManifest.fromJson(
            Map<String, Object?>.from(raw),
            maxBytes: maxDocumentBytes,
          ),
        );
      } on TransferValidationException catch (error) {
        throw ShareOfferException(error.message, code: error.code);
      }
    }
    return ShareOffer.validated(
      batchId: batchId,
      files: files,
      maxBatchBytes: maxBatchBytes,
    );
  }
}

/// Maximum accepted size of a control message carrying an offer. The frame
/// codec already bounds control frames; this keeps offer parsing predictable.
const int shareMaxOfferJsonBytes = 32 * 1024;
