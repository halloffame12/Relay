import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:relay/features/library/data/local_document_file_store.dart';
import 'package:relay/features/library/domain/document.dart';
import 'package:relay/features/library/domain/document_file_store.dart';

void main() {
  late Directory root;
  late Directory library;
  late LocalDocumentFileStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('relay_store_test_');
    library = Directory(p.join(root.path, 'library'));
    store = LocalDocumentFileStore(library);
  });

  tearDown(() async {
    try {
      await root.delete(recursive: true);
    } on FileSystemException {
      // Windows may briefly retain a handle after a failed copy.
    }
  });

  test('probes a real EPUB and verifies its streaming checksum', () async {
    final source = File('test/fixtures/sample.epub');
    final bytes = await source.readAsBytes();

    final probe = await store.probe(
      source.path,
      format: DocumentFormat.epub,
      maxBytes: 10 * 1024 * 1024,
    );

    expect(probe.sizeBytes, bytes.length);
    expect(probe.sha256, sha256.convert(bytes).toString());
  });

  test('rejects a mismatched file signature before copying', () async {
    final source = File(p.join(root.path, 'not-really.epub'));
    await source.writeAsString('This is plain text, not a ZIP container.');

    await expectLater(
      store.probe(
        source.path,
        format: DocumentFormat.epub,
        maxBytes: 1024 * 1024,
      ),
      throwsA(
        isA<DocumentFileException>().having(
          (error) => error.code,
          'code',
          DocumentFileErrorCode.invalidFormat,
        ),
      ),
    );
  });

  test(
    'copies with a safe unique internal name and preserves the bytes',
    () async {
      final source = File('test/fixtures/sample.epub');
      final bytes = await source.readAsBytes();
      final digest = sha256.convert(bytes).toString();

      final first = await store.copyIntoLibrary(
        sourcePath: source.path,
        displayName: '../Field Notes.epub',
        format: DocumentFormat.epub,
        expectedSizeBytes: bytes.length,
        expectedSha256: digest,
      );
      final second = await store.copyIntoLibrary(
        sourcePath: source.path,
        displayName: '../Field Notes.epub',
        format: DocumentFormat.epub,
        expectedSizeBytes: bytes.length,
        expectedSha256: digest,
      );

      expect(first.storedFileName, isNot(second.storedFileName));
      expect(first.storedFileName, isNot(contains('..')));
      expect(first.storedFileName, endsWith('.epub'));
      expect(await File(first.filePath).readAsBytes(), bytes);
      expect(await store.exists(first.storedFileName), isTrue);
      expect(
        () => store.pathFor('../outside.epub'),
        throwsA(isA<DocumentFileException>()),
      );
    },
  );

  test('does not leave a partial file when an import is cancelled', () async {
    final source = File('test/fixtures/sample.epub');
    final bytes = await source.readAsBytes();
    final digest = sha256.convert(bytes).toString();

    await expectLater(
      store.copyIntoLibrary(
        sourcePath: source.path,
        displayName: 'Cancelled.epub',
        format: DocumentFormat.epub,
        expectedSizeBytes: bytes.length,
        expectedSha256: digest,
        isCancelled: () => true,
      ),
      throwsA(
        isA<DocumentFileException>().having(
          (error) => error.code,
          'code',
          DocumentFileErrorCode.cancelled,
        ),
      ),
    );

    final remaining = await library.exists()
        ? await library.list().toList()
        : <FileSystemEntity>[];
    expect(remaining, isEmpty);
  });

  test('rejects a size mismatch and cleans up the destination', () async {
    final source = File('test/fixtures/sample.epub');
    final bytes = await source.readAsBytes();
    final digest = sha256.convert(bytes).toString();

    await expectLater(
      store.copyIntoLibrary(
        sourcePath: source.path,
        displayName: 'Changed.epub',
        format: DocumentFormat.epub,
        expectedSizeBytes: bytes.length + 12,
        expectedSha256: digest,
      ),
      throwsA(isA<DocumentFileException>()),
    );
    expect(await library.list().toList(), isEmpty);
  });
}
