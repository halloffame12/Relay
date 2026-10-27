import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:relay/app/app.dart';
import 'package:relay/core/providers/app_providers.dart';
import 'package:relay/core/storage/app_database.dart';
import 'package:relay/core/storage/database_providers.dart';
import 'package:relay/core/storage/storage_providers.dart';
import 'package:relay/features/library/application/library_providers.dart';
import 'package:relay/features/library/data/drift_document_repository.dart';
import 'package:relay/features/library/data/local_document_file_store.dart';
import 'package:relay/features/library/domain/document.dart';
import 'package:relay/features/library/domain/document_repository.dart';
import 'package:relay/features/reader/application/reading_providers.dart';
import 'package:relay/features/reader/data/drift_reading_progress_repository.dart';
import 'package:relay/features/reader/domain/epub_document.dart';
import 'package:relay/features/reader/domain/pdf_document.dart';
import 'package:relay/features/reader/domain/reader_content.dart';
import 'package:relay/features/reader/domain/reading_progress.dart';
import 'package:relay/features/reader/domain/reading_progress_repository.dart';
import 'package:relay/features/transfers/application/transfer_providers.dart';
import 'package:relay/features/transfers/domain/transfer_invitation.dart';
import 'package:relay/features/transfers/domain/transfer_service.dart';
import 'package:relay/features/transfers/domain/transfer_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestHarness {
  TestHarness._({
    required this.root,
    required this.dataDirectory,
    required this.libraryDirectory,
    required this.database,
    required this.fileStore,
    required this.repository,
    required this.progressRepository,
    required this.pdfService,
  });

  final Directory root;
  final Directory dataDirectory;
  final Directory libraryDirectory;
  final AppDatabase database;
  final LocalDocumentFileStore fileStore;
  final DriftDocumentRepository repository;
  final DriftReadingProgressRepository progressRepository;
  final FakePdfDocumentService pdfService;

  late final Document epubDocument;
  late final Document pdfDocument;
  final List<Document> _documents = [];

  List<Document> get documents => List.unmodifiable(_documents);

  static Future<TestHarness> create({bool seed = true}) async {
    final root = await Directory.systemTemp.createTemp('relay_test_');
    final data = Directory(p.join(root.path, 'data'))..createSync();
    final library = Directory(p.join(root.path, 'library'))..createSync();
    final database = AppDatabase.forTesting(
      NativeDatabase(File(p.join(data.path, 'relay.sqlite'))),
    );
    final fileStore = LocalDocumentFileStore(library);
    final harness = TestHarness._(
      root: root,
      dataDirectory: data,
      libraryDirectory: library,
      database: database,
      fileStore: fileStore,
      repository: DriftDocumentRepository(database, fileStore),
      progressRepository: DriftReadingProgressRepository(database),
      pdfService: FakePdfDocumentService(pageCount: 3),
    );
    if (seed) await harness.seed();
    return harness;
  }

  Future<void> seed() async {
    final epubSource = File('test/fixtures/sample.epub');
    epubDocument = await _addFile(
      source: epubSource,
      displayName: 'The Quiet Orchard.epub',
      format: DocumentFormat.epub,
      title: 'The Quiet Orchard',
      author: 'Mara Venn',
      description: 'A short test book about attention and orchards.',
      pageCount: null,
      addedDaysAgo: 2,
      coverDesign: CoverDesign.arch,
      coverPalette: CoverPalette.sage,
    );

    final pdfSource = File(p.join(root.path, 'Designing for Attention.pdf'));
    await pdfSource.writeAsBytes(
      utf8.encode(
        '%PDF-1.4\n'
        '1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n'
        '2 0 obj<</Type/Pages/Count 3/Kids[3 0 R]>>endobj\n'
        '3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 595 842]>>endobj\n'
        'trailer<</Root 1 0 R>>\n%%EOF\n',
      ),
    );
    pdfDocument = await _addFile(
      source: pdfSource,
      displayName: 'Designing for Attention.pdf',
      format: DocumentFormat.pdf,
      title: 'Designing for Attention',
      author: 'Unknown author',
      description: 'PDF test fixture stored by Relay.',
      pageCount: 3,
      addedDaysAgo: 1,
      coverDesign: CoverDesign.minimal,
      coverPalette: CoverPalette.clay,
    );
  }

  Future<Document> _addFile({
    required File source,
    required String displayName,
    required DocumentFormat format,
    required String title,
    required String author,
    required String description,
    required int? pageCount,
    required int addedDaysAgo,
    required CoverDesign coverDesign,
    required CoverPalette coverPalette,
  }) async {
    final bytes = await source.readAsBytes();
    final digest = sha256.convert(bytes).toString();
    final stored = await fileStore.copyIntoLibrary(
      sourcePath: source.path,
      displayName: displayName,
      format: format,
      expectedSizeBytes: bytes.length,
      expectedSha256: digest,
    );
    final document = Document(
      id: 'test-${digest.substring(0, 12)}',
      title: title,
      author: author,
      source: 'Imported from this device',
      format: format,
      sizeBytes: stored.sizeBytes,
      addedAt: DateTime.now().subtract(Duration(days: addedDaysAgo)),
      description: description,
      coverDesign: coverDesign,
      coverPalette: coverPalette,
      language: 'en',
      pageCount: pageCount,
      isImported: true,
      fileName: displayName,
      storedFileName: stored.storedFileName,
      sha256: digest,
    );
    await repository.addDocument(document);
    _documents.add(document);
    return document;
  }

  Future<Widget> buildApp({
    Map<String, ReadingProgress> progress = const {},
    List<Document>? documents,
    List<TransferTask> transfers = const [],
    ReceiverEndpoint receiver = const ReceiverEndpoint.idle(),
    List<IncomingTransferRequest> incomingRequests = const [],
    TransferService? transferService,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final visibleDocuments = documents ?? this.documents;
    final fakeTransferService = transferService ?? FakeTransferService();
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        appDataDirectoryProvider.overrideWithValue(dataDirectory),
        documentLibraryDirectoryProvider.overrideWithValue(libraryDirectory),
        appDatabaseProvider.overrideWithValue(database),
        documentFileStoreProvider.overrideWithValue(fileStore),
        pdfDocumentServiceProvider.overrideWithValue(pdfService),
        readerContentServiceProvider.overrideWithValue(
          _FakeReaderContentService(pdfService),
        ),
        documentRepositoryProvider.overrideWithValue(
          _FakeDocumentRepository(visibleDocuments),
        ),
        readingProgressRepositoryProvider.overrideWithValue(
          _FakeReadingProgressRepository(progress),
        ),
        // Widget tests use seeded values instead of Drift query streams. Drift
        // schedules zero-duration timers when a stream is disposed, which the
        // Flutter test binding reports as pending timers. The database itself
        // is still exercised by the repository and progress tests.
        documentsProvider.overrideWith(
          (ref) => Stream<List<Document>>.value(visibleDocuments),
        ),
        readingProgressProvider.overrideWith(
          (ref) => Stream<Map<String, ReadingProgress>>.value(progress),
        ),
        // Transfer services are real TCP/Drift implementations in production.
        // Widget tests use fixed values so they never open sockets or leave
        // database stream timers pending.
        transferServiceProvider.overrideWithValue(fakeTransferService),
        transfersProvider.overrideWith(
          (ref) => Stream<List<TransferTask>>.value(transfers),
        ),
        receiverEndpointProvider.overrideWith(
          (ref) => Stream<ReceiverEndpoint>.value(receiver),
        ),
        incomingTransferRequestsProvider.overrideWith(
          (ref) =>
              Stream<List<IncomingTransferRequest>>.value(incomingRequests),
        ),
      ],
      child: const RelayApp(),
    );
  }

  Future<void> dispose() async {
    await database.close();
    try {
      await root.delete(recursive: true);
    } on FileSystemException {
      // Windows can briefly hold a file handle after the database closes.
    }
  }
}

class FakeTransferService implements TransferService {
  FakeTransferService({
    this.receiver = const ReceiverEndpoint.idle(),
    this.connectError,
    this.transferError,
    ConnectedPeer? connectedPeer,
  }) : connectedPeer =
           connectedPeer ??
           const ConnectedPeer(
             id: 'peer-1',
             deviceName: 'Receiver phone',
             address: '192.168.1.20',
             port: 40404,
           );

  ReceiverEndpoint receiver;
  Object? connectError;
  Object? transferError;
  ConnectedPeer connectedPeer;

  final List<TransferInvitation> connectedInvitations = [];
  final List<String> disconnectedPeerIds = [];
  final List<String> peerSendCalls = [];
  final List<String> manualSendCalls = [];

  @override
  ReceiverEndpoint get currentReceiver => receiver;

  @override
  Future<void> approveIncoming(String transferId) async {}

  @override
  Future<void> cancel(String transferId) async {}

  @override
  Future<void> clearCompleted() async {}

  @override
  void dispose() {}

  @override
  Future<void> recoverIncompleteTransfers() async {}

  @override
  Future<void> rejectIncoming(String transferId) async {}

  @override
  Future<void> removeTransfer(String transferId) async {}

  @override
  Future<ConnectedPeer> connectWithInvitation(
    TransferInvitation invitation,
  ) async {
    connectedInvitations.add(invitation);
    if (connectError != null) throw connectError!;
    return connectedPeer;
  }

  @override
  Future<TransferTask> sendDocumentToPeer({
    required String documentId,
    required String peerId,
  }) async {
    peerSendCalls.add('$documentId@$peerId');
    if (transferError != null) throw transferError!;
    return _task(documentId: documentId, deviceName: connectedPeer.deviceName);
  }

  @override
  Future<void> disconnectPeer(String peerId) async {
    disconnectedPeerIds.add(peerId);
  }

  @override
  Future<TransferTask> sendDocument({
    required String documentId,
    required String host,
    required int port,
    required String pairingCode,
  }) async {
    manualSendCalls.add('$documentId@$host:$port:$pairingCode');
    if (transferError != null) throw transferError!;
    return _task(documentId: documentId, deviceName: host);
  }

  TransferTask _task({required String documentId, required String deviceName}) {
    final now = DateTime.now();
    return TransferTask(
      id: 'fake-${manualSendCalls.length}-${peerSendCalls.length}',
      documentId: documentId,
      documentTitle: 'Test document',
      fileTypeLabel: 'EPUB',
      sizeBytes: 1024,
      direction: TransferDirection.send,
      deviceName: deviceName,
      status: TransferStatus.completed,
      createdAt: now,
      updatedAt: now,
      transferredBytes: 1024,
      completedAt: now,
    );
  }

  @override
  Future<void> stopReceiving() async {
    receiver = const ReceiverEndpoint.idle();
  }

  @override
  Future<ReceiverEndpoint> refreshInvitation() async => receiver;

  @override
  Stream<List<IncomingTransferRequest>> watchIncomingRequests() =>
      Stream<List<IncomingTransferRequest>>.value(
        const <IncomingTransferRequest>[],
      );

  @override
  Stream<ReceiverEndpoint> watchReceiver() =>
      Stream<ReceiverEndpoint>.value(receiver);

  @override
  Stream<List<TransferTask>> watchTransfers() =>
      Stream<List<TransferTask>>.value(const <TransferTask>[]);

  @override
  Future<ReceiverEndpoint> startReceiving() async => receiver;
}

class FakePdfDocumentService implements PdfDocumentService {
  FakePdfDocumentService({this.pageCount = 3});

  final int pageCount;

  @override
  Future<PdfDocumentHandle> open(String path) async {
    return FakePdfDocumentHandle(pageCount: pageCount);
  }

  @override
  Future<PdfInspection> inspect(String path) async {
    return PdfInspection(pageCount: pageCount);
  }
}

class FakePdfDocumentHandle implements PdfDocumentHandle {
  FakePdfDocumentHandle({required this.pageCount});

  @override
  final int pageCount;

  static final Uint8List _pixel = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
    'YAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
  );

  @override
  Future<PdfPageBitmap> renderPage(
    int index, {
    required double targetWidth,
  }) async {
    if (index < 0 || index >= pageCount) {
      throw const PdfContentException('Page outside fake PDF.');
    }
    return PdfPageBitmap(bytes: _pixel, width: 1, height: 1);
  }

  @override
  Future<void> close() async {}
}

class _FakeReaderContentService implements ReaderContentService {
  _FakeReaderContentService(this._pdfService);

  final FakePdfDocumentService _pdfService;

  static const _book = EpubDocument(
    title: 'The Quiet Orchard',
    author: 'Mara Venn',
    language: 'en',
    description: 'A test book.',
    chapters: [
      EpubChapter(
        id: 'chapter1.xhtml',
        title: 'Attention',
        blocks: [
          EpubBlock(kind: EpubBlockKind.heading, text: 'Attention'),
          EpubBlock(
            kind: EpubBlockKind.paragraph,
            text:
                'This is a real EPUB stored by Relay for an offline reading '
                'test.',
          ),
          EpubBlock(
            kind: EpubBlockKind.paragraph,
            text:
                'The reader preserves paragraphs, chapters and a saved place.',
          ),
        ],
      ),
      EpubChapter(
        id: 'chapter2.xhtml',
        title: 'The Orchard',
        blocks: [
          EpubBlock(kind: EpubBlockKind.heading, text: 'The Orchard'),
          EpubBlock(
            kind: EpubBlockKind.paragraph,
            text: 'The orchard keeps its own time while the reader follows.',
          ),
        ],
      ),
    ],
  );

  @override
  Future<ReaderContent> open(Document document) async {
    return switch (document.format) {
      DocumentFormat.pdf => PdfReaderContent(
        FakePdfDocumentHandle(pageCount: _pdfService.pageCount),
      ),
      DocumentFormat.epub => const EpubReaderContent(_book),
    };
  }
}

class _FakeDocumentRepository implements DocumentRepository {
  _FakeDocumentRepository(List<Document> documents)
    : _documents = List<Document>.of(documents);

  final List<Document> _documents;

  @override
  Future<void> addDocument(Document document) async {
    _documents.add(document);
  }

  @override
  Future<Document?> findById(String id) async {
    for (final document in _documents) {
      if (document.id == id) return document;
    }
    return null;
  }

  @override
  Future<Document?> findBySha256(String sha256) async {
    for (final document in _documents) {
      if (document.sha256 == sha256) return document;
    }
    return null;
  }

  @override
  Future<List<Document>> getDocuments() async =>
      List<Document>.unmodifiable(_documents);

  @override
  Future<void> markOpened(String id) async {}

  @override
  Future<DocumentRemovalResult> removeDocument(String id) async {
    _documents.removeWhere((document) => document.id == id);
    return const DocumentRemovalResult(fileRemoved: true);
  }

  @override
  Future<void> updatePageCount(String id, int? pageCount) async {}

  @override
  Stream<List<Document>> watchDocuments() =>
      Stream<List<Document>>.value(List<Document>.unmodifiable(_documents));
}

class _FakeReadingProgressRepository implements ReadingProgressRepository {
  _FakeReadingProgressRepository(Map<String, ReadingProgress> progress)
    : _values = Map<String, ReadingProgress>.of(progress);

  final Map<String, ReadingProgress> _values;

  @override
  Future<void> clearAll() async => _values.clear();

  @override
  Future<void> saveProgress(ReadingProgress progress) async {
    _values[progress.documentId] = progress;
  }

  @override
  Stream<Map<String, ReadingProgress>> watchProgress() =>
      Stream<Map<String, ReadingProgress>>.value(
        Map<String, ReadingProgress>.unmodifiable(_values),
      );
}
