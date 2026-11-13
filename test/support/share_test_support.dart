import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:relay/features/import/domain/document_import_service.dart';
import 'package:relay/features/library/domain/document.dart';
import 'package:relay/features/library/domain/document_file_store.dart';
import 'package:relay/features/library/domain/document_repository.dart';
import 'package:relay/features/share/data/share_link.dart';
import 'package:relay/features/share/data/share_service.dart';
import 'package:relay/features/share/domain/share_invitation.dart';
import 'package:relay/features/transfers/data/incoming_transfer_handler.dart';
import 'package:relay/features/transfers/domain/transfer_limits.dart';
import 'package:relay/features/transfers/domain/transfer_manifest.dart';

/// One end of an in-memory pair that satisfies [ShareLink]. Bytes added to one
/// end are delivered to the other end in order, which is enough to exercise the
/// session protocol without a socket or a TURN deployment.
class MemoryShareLink implements ShareLink {
  MemoryShareLink({required this.path});

  final StreamController<Uint8List> _incoming = StreamController<Uint8List>();
  MemoryShareLink? peer;
  bool _closed = false;

  /// Optional hook applied to bytes before they reach the peer. Tests use it to
  /// corrupt a data frame without touching the session code.
  Uint8List Function(Uint8List bytes)? onAdd;

  @override
  final SharePath path;

  @override
  Stream<Uint8List> get incoming => _incoming.stream;

  @override
  bool get isOpen => !_closed;

  @override
  int get bufferedAmount => 0;

  @override
  int get preferredChunkBytes => 4096;

  @override
  void add(Uint8List bytes) {
    if (_closed) {
      throw const ShareLinkException('The connection is closed.');
    }
    final target = peer;
    if (target == null || target._closed) {
      throw const ShareLinkException('The connection is closed.');
    }
    final payload = onAdd?.call(bytes) ?? bytes;
    target._incoming.add(payload);
  }

  @override
  Future<void> drain() async {}

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    // Do not await `close()` on a controller that was never listened to: its
    // done event has nowhere to go, so the future would never complete. The
    // production TCP and WebRTC links close real transports here.
    unawaited(_incoming.close());
    final target = peer;
    if (target != null && !target._incoming.isClosed) {
      unawaited(target._incoming.close());
    }
  }
}

({MemoryShareLink sender, MemoryShareLink receiver}) memoryShareLinkPair({
  SharePath path = SharePath.direct,
}) {
  final sender = MemoryShareLink(path: path);
  final receiver = MemoryShareLink(path: path);
  sender.peer = receiver;
  receiver.peer = sender;
  return (sender: sender, receiver: receiver);
}

class FakeWebRtcConnector implements WebRtcConnector {
  final Map<String, Completer<ShareLink>> _rooms = {};
  final List<ShareInvitation> senderInvitations = [];
  final List<ShareInvitation> receiverInvitations = [];

  MemoryShareLink? senderLink;
  MemoryShareLink? receiverLink;

  @override
  Future<ShareLink> connectSender({
    required ShareInvitation invitation,
    required String deviceName,
    required Duration timeout,
  }) async {
    senderInvitations.add(invitation);
    final room = Completer<ShareLink>();
    _rooms[invitation.sessionId] = room;
    final pair = memoryShareLinkPair();
    senderLink = pair.sender;
    receiverLink = pair.receiver;
    room.complete(pair.receiver);
    return pair.sender;
  }

  @override
  Future<ShareLink> connectReceiver({
    required ShareInvitation invitation,
    required String deviceName,
    required Duration timeout,
  }) async {
    receiverInvitations.add(invitation);
    final room = _rooms[invitation.sessionId];
    if (room == null) {
      throw const ShareException(
        'No signaling room is open for this code.',
        code: 'room_missing',
      );
    }
    return room.future.timeout(timeout);
  }
}

class FakeShareIncomingHandler implements IncomingTransferHandler {
  FakeShareIncomingHandler(this.libraryDirectory);

  final Directory libraryDirectory;
  final Set<String> _knownHashes = <String>{};
  final List<TransferManifest> imported = <TransferManifest>[];
  final List<Uint8List> importedBytes = <Uint8List>[];
  final List<String> transportLabels = <String>[];

  void markExisting(String sha256) => _knownHashes.add(sha256);

  @override
  Future<ImportResult> importVerifiedFile({
    required String temporaryPath,
    required TransferManifest manifest,
    required String peerName,
    String transportLabel = 'Wi-Fi',
  }) async {
    final bytes = await File(temporaryPath).readAsBytes();
    if (!_knownHashes.add(manifest.sha256)) {
      return ImportResult.duplicate(_receivedDocument(manifest));
    }
    imported.add(manifest);
    importedBytes.add(bytes);
    transportLabels.add(transportLabel);
    await Directory(libraryDirectory.path).create(recursive: true);
    final destination = File(
      p.join(libraryDirectory.path, '${imported.length}-${manifest.fileName}'),
    );
    await destination.writeAsBytes(bytes, flush: true);
    return ImportResult.success(_receivedDocument(manifest));
  }

  Document _receivedDocument(TransferManifest manifest) {
    return Document(
      id: 'received-${manifest.sha256.substring(0, 12)}',
      title: manifest.title,
      author: 'Unknown author',
      source: 'Received by Relay',
      format: manifest.format,
      sizeBytes: manifest.sizeBytes,
      addedAt: DateTime.now(),
      description: 'A verified share fixture.',
      coverDesign: CoverDesign.minimal,
      coverPalette: CoverPalette.ink,
      fileName: manifest.fileName,
      storedFileName: manifest.fileName,
      sha256: manifest.sha256,
      isImported: true,
    );
  }
}

class FakeShareDocumentRepository implements DocumentRepository {
  FakeShareDocumentRepository([Iterable<Document> documents = const []]) {
    for (final document in documents) {
      _documents[document.id] = document;
    }
  }

  final Map<String, Document> _documents = <String, Document>{};

  @override
  Future<Document?> findById(String id) async => _documents[id];

  @override
  Future<Document?> findBySha256(String sha256) async {
    for (final document in _documents.values) {
      if (document.sha256 == sha256) return document;
    }
    return null;
  }

  @override
  Future<List<Document>> getDocuments() async =>
      List<Document>.unmodifiable(_documents.values);

  @override
  Stream<List<Document>> watchDocuments() => Stream<List<Document>>.value(
    List<Document>.unmodifiable(_documents.values),
  );

  @override
  Future<void> addDocument(Document document) async {
    _documents[document.id] = document;
  }

  @override
  Future<void> markOpened(String id) async {}

  @override
  Future<void> updatePageCount(String id, int? pageCount) async {}

  @override
  Future<DocumentRemovalResult> removeDocument(String id) async {
    _documents.remove(id);
    return const DocumentRemovalResult(fileRemoved: true);
  }
}

class FakeShareFileStore implements DocumentFileStore {
  FakeShareFileStore(this.libraryDirectory);

  final Directory libraryDirectory;

  @override
  String pathFor(String storedFileName) =>
      p.join(libraryDirectory.path, storedFileName);

  @override
  Future<bool> exists(String storedFileName) =>
      File(pathFor(storedFileName)).exists();

  @override
  Future<DocumentProbe> probe(
    String sourcePath, {
    required DocumentFormat format,
    required int maxBytes,
  }) async {
    final file = File(sourcePath);
    final bytes = await file.length();
    return DocumentProbe(sizeBytes: bytes, sha256: '0' * 64);
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
    final destination = File(pathFor(displayName));
    await File(sourcePath).copy(destination.path);
    return StoredDocumentFile(
      storedFileName: displayName,
      filePath: destination.path,
      sizeBytes: expectedSizeBytes,
      sha256: expectedSha256,
    );
  }

  @override
  Future<void> delete(String storedFileName) async {
    final file = File(pathFor(storedFileName));
    if (await file.exists()) await file.delete();
  }
}

/// Wires a [ShareService] to in-memory transports and temporary folders.
class ShareTestHarness {
  ShareTestHarness._({
    required this.root,
    required this.libraryDirectory,
    required this.temporaryDirectory,
    required this.repository,
    required this.fileStore,
    required this.handler,
    required this.connector,
    required this.service,
  });

  final Directory root;
  final Directory libraryDirectory;
  final Directory temporaryDirectory;
  final FakeShareDocumentRepository repository;
  final FakeShareFileStore fileStore;
  final FakeShareIncomingHandler handler;
  final FakeWebRtcConnector connector;
  final ShareService service;

  static Future<ShareTestHarness> create({bool crossNetwork = true}) async {
    final root = await Directory.systemTemp.createTemp('relay_share_test_');
    final library = Directory(p.join(root.path, 'library'))..createSync();
    final temporary = Directory(p.join(root.path, 'temp'))..createSync();
    final repository = FakeShareDocumentRepository();
    final fileStore = FakeShareFileStore(library);
    final handler = FakeShareIncomingHandler(library);
    final connector = FakeWebRtcConnector();
    final service = ShareService(
      documentRepository: repository,
      fileStore: fileStore,
      incomingHandler: handler,
      temporaryDirectory: temporary,
      deviceName: 'Test sender',
      limits: const TransferLimits(
        approvalTimeout: Duration(seconds: 10),
        handshakeTimeout: Duration(seconds: 5),
        verificationTimeout: Duration(seconds: 5),
        inactivityTimeout: Duration(seconds: 5),
        invitationTtl: Duration(minutes: 5),
      ),
      webRtcConnector: crossNetwork ? connector : null,
      signalingUrl: '',
      localAddressResolver: () async => const <String>[],
      freeSpaceProbe: (_) async => null,
    );
    return ShareTestHarness._(
      root: root,
      libraryDirectory: library,
      temporaryDirectory: temporary,
      repository: repository,
      fileStore: fileStore,
      handler: handler,
      connector: connector,
      service: service,
    );
  }

  Future<Document> addDocument({
    required String id,
    required String fileName,
    required List<int> bytes,
    DocumentFormat format = DocumentFormat.pdf,
    String? title,
  }) async {
    final file = File(p.join(libraryDirectory.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    final document = Document(
      id: id,
      title: title ?? p.basenameWithoutExtension(fileName),
      author: 'Test author',
      source: 'Imported on this device',
      format: format,
      sizeBytes: bytes.length,
      addedAt: DateTime.now(),
      description: 'A share test fixture.',
      coverDesign: CoverDesign.minimal,
      coverPalette: CoverPalette.ink,
      fileName: fileName,
      storedFileName: fileName,
      sha256: sha256Hex(bytes),
      isImported: true,
    );
    await repository.addDocument(document);
    return document;
  }

  Future<void> dispose() async {
    await service.dispose();
    try {
      await root.delete(recursive: true);
    } on FileSystemException {
      // Windows can briefly hold a file handle after the database closes.
    }
  }
}

Future<void> waitFor(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      throw StateError('Timed out waiting for the share state.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

String sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();
