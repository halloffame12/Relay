import 'package:flutter_test/flutter_test.dart';
import 'package:relay/features/library/domain/document.dart';
import 'package:relay/features/share/domain/share_offer.dart';
import 'package:relay/features/transfers/domain/transfer_manifest.dart';

TransferManifest _manifest({
  String fileName = 'book.pdf',
  String title = 'Book',
  String? sha256,
  int sizeBytes = 1024,
}) {
  return TransferManifest.validated(
    fileName: fileName,
    title: title,
    format: fileName.endsWith('.epub') ? 'epub' : 'pdf',
    sizeBytes: sizeBytes,
    sha256: sha256 ?? 'a' * 64,
    maxBytes: 100 * 1024 * 1024,
  );
}

Matcher _failsWith(String code) => throwsA(
  isA<ShareOfferException>().having((error) => error.code, 'code', code),
);

void main() {
  group('ShareOffer', () {
    test('keeps the ordered file list and computes totals', () {
      final offer = ShareOffer.validated(
        batchId: 'batch-1234567890',
        files: [
          _manifest(fileName: 'first.pdf', sizeBytes: 1000),
          _manifest(fileName: 'second.epub', sha256: 'b' * 64, sizeBytes: 2048),
        ],
      );

      expect(offer.fileCount, 2);
      expect(offer.totalBytes, 3048);
      expect(offer.files.first.fileName, 'first.pdf');
      expect(offer.files.last.format, DocumentFormat.epub);
    });

    test('rejects an empty batch', () {
      expect(
        () =>
            ShareOffer.validated(batchId: 'batch-1234567890', files: const []),
        _failsWith('empty_offer'),
      );
    });

    test('rejects invalid batch identifiers', () {
      for (final id in ['short', 'has space', 'x' * 33, '']) {
        expect(
          () => ShareOffer.validated(batchId: id, files: [_manifest()]),
          _failsWith('invalid_batch'),
        );
      }
    });

    test('rejects more files than the batch limit', () {
      final files = [
        for (var index = 0; index < shareMaxFilesPerBatch + 1; index++)
          _manifest(
            fileName: 'file-$index.pdf',
            sha256: index.toRadixString(16).padLeft(64, '0'),
          ),
      ];
      expect(
        () => ShareOffer.validated(batchId: 'batch-1234567890', files: files),
        _failsWith('too_many_files'),
      );
    });

    test('rejects duplicate file names regardless of case', () {
      expect(
        () => ShareOffer.validated(
          batchId: 'batch-1234567890',
          files: [
            _manifest(fileName: 'Book.pdf', sizeBytes: 10),
            _manifest(fileName: 'book.pdf', sha256: 'b' * 64, sizeBytes: 10),
          ],
        ),
        _failsWith('duplicate_file_name'),
      );
    });

    test('rejects a batch over the byte limit', () {
      expect(
        () => ShareOffer.validated(
          batchId: 'batch-1234567890',
          files: [_manifest(sizeBytes: 2048)],
          maxBatchBytes: 1024,
        ),
        _failsWith('batch_too_large'),
      );
    });

    test('round-trips through JSON', () {
      final offer = ShareOffer.validated(
        batchId: 'batch-1234567890',
        files: [
          _manifest(fileName: 'first.pdf', sizeBytes: 12),
          _manifest(fileName: 'second.epub', sha256: 'c' * 64, sizeBytes: 34),
        ],
      );

      final parsed = ShareOffer.fromJson(offer.toJson());

      expect(parsed.batchId, offer.batchId);
      expect(parsed.totalBytes, offer.totalBytes);
      expect(
        parsed.files.map((file) => file.fileName),
        offer.files.map((file) => file.fileName),
      );
    });

    test('rejects unknown fields and malformed payloads', () {
      expect(
        () => ShareOffer.fromJson({
          'batchId': 'batch-1234567890',
          'files': <Object?>[],
          'extra': true,
        }),
        _failsWith('invalid_offer'),
      );
      expect(
        () => ShareOffer.fromJson({'batchId': 7, 'files': <Object?>[]}),
        _failsWith('invalid_offer'),
      );
      expect(
        () => ShareOffer.fromJson({
          'batchId': 'batch-1234567890',
          'files': [1],
        }),
        _failsWith('invalid_offer'),
      );
      expect(
        () => ShareOffer.fromJson({
          'batchId': 'batch-1234567890',
          'files': [
            {
              'fileName': '../escape.pdf',
              'title': 'Book',
              'format': 'pdf',
              'sizeBytes': 10,
              'sha256': 'a' * 64,
            },
          ],
        }),
        _failsWith('unsafe_name'),
      );
    });

    test('rejects a raw list larger than the batch limit', () {
      final manifest = _manifest().toJson();
      expect(
        () => ShareOffer.fromJson({
          'batchId': 'batch-1234567890',
          'files': [
            for (var index = 0; index < shareMaxFilesPerBatch + 1; index++)
              {...manifest, 'fileName': 'file-$index.pdf'},
          ],
        }),
        _failsWith('too_many_files'),
      );
    });
  });
}
