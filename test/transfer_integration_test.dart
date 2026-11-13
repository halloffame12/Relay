import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:relay/core/storage/app_database.dart';
import 'package:relay/features/import/data/document_metadata_service.dart';
import 'package:relay/features/import/data/file_picker_document_import_service.dart';
import 'package:relay/features/library/data/drift_document_repository.dart';
import 'package:relay/features/library/data/local_document_file_store.dart';
import 'package:relay/features/library/domain/document.dart';
import 'package:relay/features/transfers/data/drift_transfer_repository.dart';
import 'package:relay/features/transfers/data/incoming_transfer_handler.dart';
import 'package:relay/features/transfers/data/relay_transfer_service.dart';
import 'package:relay/features/transfers/data/transfer_connection.dart';
import 'package:relay/features/transfers/domain/transfer_invitation.dart';
import 'package:relay/features/transfers/domain/transfer_limits.dart';
import 'package:relay/features/transfers/domain/transfer_manifest.dart';
import 'package:relay/features/transfers/domain/transfer_protocol.dart';
import 'package:relay/features/transfers/domain/transfer_repository.dart';
import 'package:relay/features/transfers/domain/transfer_service.dart';
import 'package:relay/features/transfers/domain/transfer_task.dart';

const _loopback = '127.0.0.1';
const _shaLength = 64;

final TransferLimits _limits = const TransferLimits(
  maxDocumentBytes: 100 * 1024 * 1024,
  connectTimeout: Duration(seconds: 5),
  handshakeTimeout: Duration(seconds: 3),
  approvalTimeout: Duration(seconds: 8),
  verificationTimeout: Duration(seconds: 8),
  inactivityTimeout: Duration(seconds: 5),
  progressUpdateInterval: Duration(milliseconds: 20),
  preferredPort: 0,
);

Uint8List _pdfBytes([String marker = 'relay test']) {
  return Uint8List.fromList(utf8.encode('%PDF-1.4\n$marker\n%%EOF\n'));
}

Uint8List _largePdfBytes(int targetBytes) {
  final builder = BytesBuilder(copy: false)
    ..add(utf8.encode('%PDF-1.4\n'))
    ..add(Uint8List(targetBytes))
    ..add(utf8.encode('\n%%EOF\n'));
  return builder.takeBytes();
}

String _hashBytes(List<int> bytes) => sha256.convert(bytes).toString();

class _FakeMetadataService implements DocumentMetadataService {
  const _FakeMetadataService();

  @override
  Future<ImportedDocumentMetadata> inspect({
    required String path,
    required String displayName,
    required DocumentFormat format,
  }) async {
    return ImportedDocumentMetadata(
      title: p.basenameWithoutExtension(displayName),
      author: 'Test author',
      language: 'English',
      description: 'Test metadata for $displayName',
      pageCount: format == DocumentFormat.pdf ? 1 : null,
    );
  }
}

class _Device {
  _Device({
    required this.root,
    required this.libraryDirectory,
    required this.temporaryDirectory,
    required this.database,
    required this.fileStore,
    required this.documents,
    required this.transfers,
    required this.service,
  });

  final Directory root;
  final Directory libraryDirectory;
  final Directory temporaryDirectory;
  final AppDatabase database;
  final LocalDocumentFileStore fileStore;
  final DriftDocumentRepository documents;
  final DriftTransferRepository transfers;
  final RelayTransferService service;

  static Future<_Device> create({
    required String name,
    TransferLimits? limits,
  }) async {
    final root = await Directory.systemTemp.createTemp('relay-transfer-test-');
    final library = Directory(p.join(root.path, 'library'));
    final temporary = Directory(p.join(root.path, 'transfers'));
    final data = Directory(p.join(root.path, 'data'));
    await library.create(recursive: true);
    await data.create(recursive: true);
    final database = AppDatabase.forTesting(
      NativeDatabase(File(p.join(data.path, 'relay.sqlite'))),
    );
    final fileStore = LocalDocumentFileStore(library);
    final documents = DriftDocumentRepository(database, fileStore);
    final transfers = DriftTransferRepository(database);
    final importService = FilePickerDocumentImportService(
      repository: documents,
      fileStore: fileStore,
      metadataService: const _FakeMetadataService(),
    );
    final service = RelayTransferService(
      repository: transfers,
      documentRepository: documents,
      fileStore: fileStore,
      incomingHandler: LocalIncomingTransferHandler(importService),
      temporaryDirectory: temporary,
      deviceName: name,
      limits: limits ?? _limits,
    );
    return _Device(
      root: root,
      libraryDirectory: library,
      temporaryDirectory: temporary,
      database: database,
      fileStore: fileStore,
      documents: documents,
      transfers: transfers,
      service: service,
    );
  }

  Future<Document> addDocument({
    required String fileName,
    required List<int> bytes,
    required DocumentFormat format,
    String? title,
    String? recordedSha256,
  }) async {
    final source = File(p.join(root.path, 'source-$fileName'));
    await source.writeAsBytes(bytes, flush: true);
    final hash = _hashBytes(bytes);
    final stored = await fileStore.copyIntoLibrary(
      sourcePath: source.path,
      displayName: fileName,
      format: format,
      expectedSizeBytes: bytes.length,
      expectedSha256: hash,
    );
    final document = Document(
      id: 'doc-${DateTime.now().microsecondsSinceEpoch}',
      title: title ?? p.basenameWithoutExtension(fileName),
      author: 'Test author',
      source: 'Imported from this device',
      format: format,
      sizeBytes: bytes.length,
      addedAt: DateTime.now(),
      description: 'Test document',
      coverDesign: CoverDesign.bands,
      coverPalette: CoverPalette.forest,
      isImported: true,
      fileName: fileName,
      storedFileName: stored.storedFileName,
      sha256: recordedSha256 ?? hash,
    );
    await documents.addDocument(document);
    return document;
  }

  Future<void> dispose() async {
    service.dispose();
    await database.close();
    try {
      await root.delete(recursive: true);
    } catch (_) {}
  }
}

class _AutoApprover {
  _AutoApprover({this.reject = false});

  final bool reject;
  final Set<String> _handled = {};
  final List<String> seenIds = [];
  StreamSubscription<List<IncomingTransferRequest>>? _subscription;

  void start(TransferService service) {
    _subscription = service.watchIncomingRequests().listen((requests) {
      for (final request in requests) {
        if (!_handled.add(request.transferId)) continue;
        seenIds.add(request.transferId);
        unawaited(_decide(service, request.transferId));
      }
    });
  }

  Future<void> _decide(TransferService service, String transferId) async {
    try {
      if (reject) {
        await service.rejectIncoming(transferId);
      } else {
        await service.approveIncoming(transferId);
      }
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}

Future<void> _waitUntil(
  FutureOr<bool> Function() predicate, {
  Duration timeout = const Duration(seconds: 10),
  String reason = 'condition was not met',
}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    if (await predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail(reason);
}

Future<void> _waitForEmptyTemp(_Device device) async {
  await _waitUntil(
    () async => (await device.temporaryDirectory.list().toList()).isEmpty,
    reason: 'temporary transfer files were not cleaned up',
  );
}

TransferInvitation _loopbackInvitation(ReceiverEndpoint endpoint) {
  final invitation = endpoint.invitation;
  expect(
    invitation,
    isNotNull,
    reason: 'the receive session must publish a QR invitation',
  );
  final scanned = TransferInvitation.parse(invitation!.payload);
  return scanned.withAddresses(const [_loopback]);
}

Future<TransferConnection> _rawConnect(
  ReceiverEndpoint endpoint, {
  String peerName = 'Raw sender',
}) async {
  final socket = await Socket.connect(
    _loopback,
    endpoint.port!,
    timeout: const Duration(seconds: 5),
  );
  final connection = TransferConnection(socket, _limits);
  await connection.writeMessage(
    HelloMessage(peerName: peerName, pairingCode: endpoint.pairingCode!),
  );
  final welcome = await connection.readMessage(
    timeout: const Duration(seconds: 5),
  );
  expect(welcome, isA<WelcomeMessage>());
  return connection;
}

TransferManifest _rawManifest({
  required int sizeBytes,
  String sha256 =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  String fileName = 'raw.pdf',
}) {
  return TransferManifest.validated(
    fileName: fileName,
    title: 'Raw document',
    format: 'pdf',
    sizeBytes: sizeBytes,
    sha256: sha256,
    maxBytes: _limits.maxDocumentBytes,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('transfers a PDF, verifies it, imports it, and leaves the original '
      'unchanged', () async {
    final sender = await _Device.create(name: 'Sender phone');
    final receiver = await _Device.create(name: 'Receiver phone');
    final approver = _AutoApprover();
    addTearDown(() async {
      await approver.dispose();
      await sender.dispose();
      await receiver.dispose();
    });

    final endpoint = await receiver.service.startReceiving();
    expect(endpoint.isListening, isTrue);
    expect(endpoint.port, isNotNull);
    expect(endpoint.pairingCode, matches(RegExp(r'^\d{6}$')));
    approver.start(receiver.service);

    final bytes = _pdfBytes('successful pdf');
    final document = await sender.addDocument(
      fileName: 'meeting notes.pdf',
      bytes: bytes,
      format: DocumentFormat.pdf,
      title: 'Meeting notes',
    );
    final originalPath = sender.fileStore.pathFor(document.storedFileName!);
    final originalHash = _hashBytes(await File(originalPath).readAsBytes());

    final task = await sender.service.sendDocument(
      documentId: document.id,
      host: _loopback,
      port: endpoint.port!,
      pairingCode: endpoint.pairingCode!,
    );

    expect(task.status, TransferStatus.completed);
    expect(task.transferredBytes, bytes.length);
    expect(task.failureReason, isNull);
    expect(await sender.fileStore.exists(document.storedFileName!), isTrue);
    expect(_hashBytes(await File(originalPath).readAsBytes()), originalHash);

    final received = await receiver.documents.findBySha256(_hashBytes(bytes));
    expect(received, isNotNull);
    expect(received!.sizeBytes, bytes.length);
    expect(received.source, contains('Received from Sender phone'));
    final receivedPath = receiver.fileStore.pathFor(received.storedFileName!);
    expect(await File(receivedPath).readAsBytes(), bytes);

    final receiverTask = (await receiver.transfers.getTransfers()).single;
    expect(receiverTask.status, TransferStatus.completed);
    expect(receiverTask.direction, TransferDirection.receive);
    expect(receiverTask.transferredBytes, bytes.length);
    expect(receiverTask.documentId, received.id);
    expect(receiverTask.deviceName, 'Sender phone');

    expect(approver.seenIds, hasLength(1));
    await _waitForEmptyTemp(receiver);
  });

  test('transfers an EPUB end to end', () async {
    final sender = await _Device.create(name: 'Sender phone');
    final receiver = await _Device.create(name: 'Receiver phone');
    final approver = _AutoApprover();
    addTearDown(() async {
      await approver.dispose();
      await sender.dispose();
      await receiver.dispose();
    });
    final endpoint = await receiver.service.startReceiving();
    approver.start(receiver.service);

    final bytes = await File(
      p.join('test', 'fixtures', 'sample.epub'),
    ).readAsBytes();
    final document = await sender.addDocument(
      fileName: 'sample.epub',
      bytes: bytes,
      format: DocumentFormat.epub,
    );

    final task = await sender.service.sendDocument(
      documentId: document.id,
      host: _loopback,
      port: endpoint.port!,
      pairingCode: endpoint.pairingCode!,
    );
    expect(task.status, TransferStatus.completed);

    final received = await receiver.documents.findBySha256(_hashBytes(bytes));
    expect(received, isNotNull);
    expect(received!.format, DocumentFormat.epub);
    expect(
      await File(receiver.fileStore.pathFor(received.storedFileName!)).length(),
      bytes.length,
    );
  });

  test('a receiver rejection never imports the document', () async {
    final sender = await _Device.create(name: 'Sender phone');
    final receiver = await _Device.create(name: 'Receiver phone');
    final rejecter = _AutoApprover(reject: true);
    addTearDown(() async {
      await rejecter.dispose();
      await sender.dispose();
      await receiver.dispose();
    });
    final endpoint = await receiver.service.startReceiving();
    rejecter.start(receiver.service);

    final bytes = _pdfBytes('rejected');
    final document = await sender.addDocument(
      fileName: 'rejected.pdf',
      bytes: bytes,
      format: DocumentFormat.pdf,
    );

    final task = await sender.service.sendDocument(
      documentId: document.id,
      host: _loopback,
      port: endpoint.port!,
      pairingCode: endpoint.pairingCode!,
    );
    expect(task.status, TransferStatus.cancelled);
    expect(task.note, contains('declined'));

    final receiverTask = (await receiver.transfers.getTransfers()).single;
    expect(receiverTask.status, TransferStatus.cancelled);
    expect(receiverTask.note, contains('declined'));
    expect(await receiver.documents.findBySha256(_hashBytes(bytes)), isNull);
    await _waitForEmptyTemp(receiver);
  });

  test('a duplicate is verified but never overwrites the existing library '
      'document', () async {
    final sender = await _Device.create(name: 'Sender phone');
    final receiver = await _Device.create(name: 'Receiver phone');
    final approver = _AutoApprover();
    addTearDown(() async {
      await approver.dispose();
      await sender.dispose();
      await receiver.dispose();
    });
    final endpoint = await receiver.service.startReceiving();
    approver.start(receiver.service);

    final bytes = _pdfBytes('duplicate');
    final document = await sender.addDocument(
      fileName: 'duplicate.pdf',
      bytes: bytes,
      format: DocumentFormat.pdf,
      title: 'Duplicate document',
    );

    final first = await sender.service.sendDocument(
      documentId: document.id,
      host: _loopback,
      port: endpoint.port!,
      pairingCode: endpoint.pairingCode!,
    );
    expect(first.status, TransferStatus.completed);

    await _waitUntil(
      () =>
          receiver.service.currentReceiver.phase == ReceiverPhase.waiting &&
          receiver.service.currentReceiver.pairingCode != endpoint.pairingCode,
      reason: 'the receiver did not rotate the single-use pairing code',
    );
    final nextEndpoint = receiver.service.currentReceiver;
    final second = await sender.service.sendDocument(
      documentId: document.id,
      host: _loopback,
      port: nextEndpoint.port!,
      pairingCode: nextEndpoint.pairingCode!,
    );
    expect(second.status, TransferStatus.completed);
    expect(second.note, contains('already had'));

    await _waitUntil(
      () => receiver.service.currentReceiver.phase == ReceiverPhase.waiting,
      reason: 'the receiver did not return to waiting after the duplicate',
    );
    final staleCode = await sender.service.sendDocument(
      documentId: document.id,
      host: _loopback,
      port: endpoint.port!,
      pairingCode: endpoint.pairingCode!,
    );
    expect(staleCode.status, TransferStatus.failed);
    expect(staleCode.failureReason, contains('pairing code'));

    final library = await receiver.documents.getDocuments();
    expect(library, hasLength(1));
    final receiverTasks = await receiver.transfers.getTransfers();
    expect(receiverTasks, hasLength(2));
    expect(
      receiverTasks.where(
        (task) => task.note?.contains('Already in your library') ?? false,
      ),
      hasLength(1),
    );
    await _waitForEmptyTemp(receiver);
  });

  test('large documents stream through the socket without a full-file '
      'manifest payload', () async {
    final sender = await _Device.create(name: 'Sender phone');
    final receiver = await _Device.create(name: 'Receiver phone');
    final approver = _AutoApprover();
    addTearDown(() async {
      await approver.dispose();
      await sender.dispose();
      await receiver.dispose();
    });
    final endpoint = await receiver.service.startReceiving();
    approver.start(receiver.service);

    final bytes = _largePdfBytes(4 * 1024 * 1024);
    final document = await sender.addDocument(
      fileName: 'large.pdf',
      bytes: bytes,
      format: DocumentFormat.pdf,
    );
    expect(bytes.length, greaterThan(4 * 1024 * 1024));

    final task = await sender.service.sendDocument(
      documentId: document.id,
      host: _loopback,
      port: endpoint.port!,
      pairingCode: endpoint.pairingCode!,
    );
    expect(task.status, TransferStatus.completed);
    expect(task.transferredBytes, bytes.length);

    final received = await receiver.documents.findBySha256(_hashBytes(bytes));
    expect(received, isNotNull);
    expect(
      await File(
        receiver.fileStore.pathFor(received!.storedFileName!),
      ).length(),
      bytes.length,
    );
  });

  test('a wrong checksum is rejected, nothing is imported, and the temporary '
      'file is removed', () async {
    final receiver = await _Device.create(name: 'Receiver phone');
    final approver = _AutoApprover();
    addTearDown(() async {
      await approver.dispose();
      await receiver.dispose();
    });
    final endpoint = await receiver.service.startReceiving();
    approver.start(receiver.service);

    final connection = await _rawConnect(endpoint);
    addTearDown(connection.close);
    final bytes = _pdfBytes('bad checksum');
    final actualHash = _hashBytes(bytes);
    final wrongHash = '0' * _shaLength;
    final manifest = _rawManifest(sizeBytes: bytes.length, sha256: wrongHash);

    await connection.writeMessage(OfferMessage(manifest: manifest));
    expect(
      await connection.readMessage(timeout: const Duration(seconds: 5)),
      isA<AcceptMessage>(),
    );
    await connection.writeData(
      Uint8List.fromList(bytes),
      timeout: const Duration(seconds: 5),
    );
    await connection.writeMessage(
      CompleteMessage(sizeBytes: bytes.length, sha256: actualHash),
    );

    final error = await connection.readMessage(
      timeout: const Duration(seconds: 5),
    );
    expect(error, isA<ErrorMessage>());
    expect((error as ErrorMessage).code, 'checksum_mismatch');

    await _waitUntil(
      () async => (await receiver.transfers.getTransfers()).any(
        (task) => task.status == TransferStatus.failed,
      ),
      reason: 'receiver transfer did not fail',
    );
    final task = (await receiver.transfers.getTransfers()).single;
    expect(task.status, TransferStatus.failed);
    expect(task.failureReason, contains('checksum'));
    expect(await receiver.documents.getDocuments(), isEmpty);
    await _waitForEmptyTemp(receiver);
  });

  test('a declared size mismatch is rejected before import', () async {
    final receiver = await _Device.create(name: 'Receiver phone');
    final approver = _AutoApprover();
    addTearDown(() async {
      await approver.dispose();
      await receiver.dispose();
    });
    final endpoint = await receiver.service.startReceiving();
    approver.start(receiver.service);

    final connection = await _rawConnect(endpoint);
    addTearDown(connection.close);
    final bytes = _pdfBytes('size mismatch');
    final hash = _hashBytes(bytes);
    final manifest = _rawManifest(sizeBytes: bytes.length, sha256: hash);

    await connection.writeMessage(OfferMessage(manifest: manifest));
    expect(
      await connection.readMessage(timeout: const Duration(seconds: 5)),
      isA<AcceptMessage>(),
    );
    await connection.writeData(
      Uint8List.fromList(bytes),
      timeout: const Duration(seconds: 5),
    );
    await connection.writeMessage(
      CompleteMessage(sizeBytes: bytes.length - 1, sha256: hash),
    );

    final error = await connection.readMessage(
      timeout: const Duration(seconds: 5),
    );
    expect(error, isA<ErrorMessage>());
    expect((error as ErrorMessage).code, 'checksum_mismatch');
    expect(await receiver.documents.getDocuments(), isEmpty);
    await _waitForEmptyTemp(receiver);
  });

  test(
    'an interrupted byte stream fails and creates no library entry',
    () async {
      final receiver = await _Device.create(name: 'Receiver phone');
      final approver = _AutoApprover();
      addTearDown(() async {
        await approver.dispose();
        await receiver.dispose();
      });
      final endpoint = await receiver.service.startReceiving();
      approver.start(receiver.service);

      final connection = await _rawConnect(endpoint);
      final bytes = _pdfBytes('truncated transfer');
      final manifest = _rawManifest(
        sizeBytes: bytes.length,
        sha256: _hashBytes(bytes),
      );
      await connection.writeMessage(OfferMessage(manifest: manifest));
      expect(
        await connection.readMessage(timeout: const Duration(seconds: 5)),
        isA<AcceptMessage>(),
      );
      await connection.writeData(
        Uint8List.fromList(bytes.sublist(0, bytes.length ~/ 2)),
        timeout: const Duration(seconds: 5),
      );
      await connection.close();

      await _waitUntil(
        () async => (await receiver.transfers.getTransfers()).any(
          (task) => task.status == TransferStatus.failed,
        ),
        reason: 'interrupted transfer did not fail',
      );
      final task = (await receiver.transfers.getTransfers()).single;
      expect(task.status, TransferStatus.failed);
      expect(task.failureReason, isNotNull);
      expect(await receiver.documents.getDocuments(), isEmpty);
      await _waitForEmptyTemp(receiver);
    },
  );

  test(
    'rejects an unsupported protocol version before reading a manifest',
    () async {
      final receiver = await _Device.create(name: 'Receiver phone');
      addTearDown(receiver.dispose);
      final endpoint = await receiver.service.startReceiving();

      final socket = await Socket.connect(
        _loopback,
        endpoint.port!,
        timeout: const Duration(seconds: 5),
      );
      final connection = TransferConnection(socket, _limits);
      addTearDown(connection.close);
      await connection.writeData(
        Uint8List.fromList(
          utf8.encode(
            '${jsonEncode({'v': 3, 'type': 'hello', 'app': 'relay'})}\n',
          ),
        ),
        timeout: const Duration(seconds: 5),
      );
      final error = await connection.readMessage(
        timeout: const Duration(seconds: 5),
      );
      expect(error, isA<ErrorMessage>());
      expect((error as ErrorMessage).code, 'unsupported_version');
      expect(await receiver.transfers.getTransfers(), isEmpty);
    },
  );

  test('rejects path traversal in a remote manifest', () async {
    final receiver = await _Device.create(name: 'Receiver phone');
    addTearDown(receiver.dispose);
    final endpoint = await receiver.service.startReceiving();
    final connection = await _rawConnect(endpoint);
    addTearDown(connection.close);

    await connection.writeData(
      Uint8List.fromList(
        utf8.encode(
          '${jsonEncode({
            'v': 2,
            'type': 'offer',
            'manifest': {'fileName': '../escape.pdf', 'title': 'Escape', 'format': 'pdf', 'sizeBytes': 10, 'sha256': 'a' * _shaLength},
          })}\n',
        ),
      ),
      timeout: const Duration(seconds: 5),
    );
    final error = await connection.readMessage(
      timeout: const Duration(seconds: 5),
    );
    expect(error, isA<ErrorMessage>());
    expect((error as ErrorMessage).code, 'unsafe_name');
    expect(await receiver.transfers.getTransfers(), isEmpty);
  });

  test('refuses to send a document record without a valid checksum', () async {
    final sender = await _Device.create(name: 'Sender phone');
    addTearDown(sender.dispose);
    final document = await sender.addDocument(
      fileName: 'unverifiable.pdf',
      bytes: _pdfBytes('unverifiable'),
      format: DocumentFormat.pdf,
      recordedSha256: 'not-a-checksum',
    );

    await expectLater(
      sender.service.sendDocument(
        documentId: document.id,
        host: _loopback,
        port: 1,
        pairingCode: '123456',
      ),
      throwsA(isA<TransferRequestException>()),
    );
    expect(await sender.transfers.getTransfers(), isEmpty);
  });

  test('an unreachable receiver produces a failed sender record', () async {
    final sender = await _Device.create(name: 'Sender phone');
    addTearDown(sender.dispose);
    final reservation = await ServerSocket.bind(_loopback, 0);
    final closedPort = reservation.port;
    await reservation.close();

    final document = await sender.addDocument(
      fileName: 'unreachable.pdf',
      bytes: _pdfBytes('unreachable'),
      format: DocumentFormat.pdf,
    );
    final task = await sender.service.sendDocument(
      documentId: document.id,
      host: _loopback,
      port: closedPort,
      pairingCode: '123456',
    );
    expect(task.status, TransferStatus.failed);
    expect(task.failureReason, isNotNull);
    expect(task.transferredBytes, 0);
  });

  test('a silent receiver times out without claiming completion', () async {
    final sender = await _Device.create(
      name: 'Timeout sender',
      limits: _limits.copyWith(
        connectTimeout: const Duration(seconds: 2),
        handshakeTimeout: const Duration(milliseconds: 400),
        approvalTimeout: const Duration(seconds: 1),
        verificationTimeout: const Duration(seconds: 1),
      ),
    );
    final server = await ServerSocket.bind(_loopback, 0);
    final silentSockets = <Socket>[];
    final subscription = server.listen(silentSockets.add);
    addTearDown(() async {
      await subscription.cancel();
      for (final socket in silentSockets) {
        socket.destroy();
      }
      await server.close();
      await sender.dispose();
    });

    final document = await sender.addDocument(
      fileName: 'silent.pdf',
      bytes: _pdfBytes('silent receiver'),
      format: DocumentFormat.pdf,
    );
    final task = await sender.service.sendDocument(
      documentId: document.id,
      host: _loopback,
      port: server.port,
      pairingCode: '123456',
    );
    expect(task.status, TransferStatus.failed);
    expect(task.failureReason, isNotNull);
    expect(task.transferredBytes, 0);
  });

  test('cancelling an active outgoing transfer closes the socket and marks it '
      'cancelled', () async {
    final sender = await _Device.create(name: 'Sender phone');
    final server = await ServerSocket.bind(_loopback, 0);
    final accepted = Completer<Socket>();
    final serverSubscription = server.listen((socket) {
      if (!accepted.isCompleted) accepted.complete(socket);
    });
    final sockets = <Socket>[];
    TransferConnection? peer;
    addTearDown(() async {
      await peer?.close();
      for (final socket in sockets) {
        socket.destroy();
      }
      await serverSubscription.cancel();
      await server.close();
      await sender.dispose();
    });

    final bytes = _largePdfBytes(8 * 1024 * 1024);
    final document = await sender.addDocument(
      fileName: 'cancel.pdf',
      bytes: bytes,
      format: DocumentFormat.pdf,
    );
    final sendFuture = sender.service.sendDocument(
      documentId: document.id,
      host: _loopback,
      port: server.port,
      pairingCode: '123456',
    );
    final socket = await accepted.future.timeout(const Duration(seconds: 5));
    sockets.add(socket);
    peer = TransferConnection(socket, _limits);
    expect(
      await peer.readMessage(timeout: const Duration(seconds: 5)),
      isA<HelloMessage>(),
    );
    await peer.writeMessage(const WelcomeMessage(deviceName: 'Slow peer'));
    expect(
      await peer.readMessage(timeout: const Duration(seconds: 5)),
      isA<OfferMessage>(),
    );
    await peer.writeMessage(const AcceptMessage());

    await _waitUntil(() async {
      final tasks = await sender.transfers.getTransfers();
      return tasks.any((task) => task.status == TransferStatus.transferring);
    }, reason: 'sender never entered the transferring state');
    final sendingTask = (await sender.transfers.getTransfers()).single;
    await sender.service.cancel(sendingTask.id);

    final finalTask = await sendFuture;
    expect(finalTask.status, TransferStatus.cancelled);
    expect(finalTask.note, contains('cancelled'));
  });

  test('QR pairing holds a verified connection, waits for approval, and '
      'rotates the code after success', () async {
    final sender = await _Device.create(name: 'Sender phone');
    final receiver = await _Device.create(name: 'Receiver phone');
    addTearDown(() async {
      await sender.dispose();
      await receiver.dispose();
    });

    final bytes = _pdfBytes('qr pairing');
    final document = await sender.addDocument(
      fileName: 'QR notes.pdf',
      bytes: bytes,
      format: DocumentFormat.pdf,
      title: 'QR notes',
    );
    final endpoint = await receiver.service.startReceiving();
    expect(endpoint.phase, ReceiverPhase.waiting);
    expect(endpoint.invitation, isNotNull);
    expect(endpoint.invitation!.protocolVersion, relayProtocolVersion);
    expect(endpoint.invitation!.addresses, isNotEmpty);
    expect(endpoint.invitation!.port, endpoint.port);

    final phases = <ReceiverPhase>[];
    final phasesSubscription = receiver.service.watchReceiver().listen(
      (update) => phases.add(update.phase),
    );
    addTearDown(phasesSubscription.cancel);

    final invitation = _loopbackInvitation(endpoint);
    final peer = await sender.service.connectWithInvitation(invitation);
    expect(peer.deviceName, 'Receiver phone');
    expect(peer.address, _loopback);
    expect(peer.port, endpoint.port);

    await _waitUntil(
      () => receiver.service.currentReceiver.phase == ReceiverPhase.connected,
      reason: 'the receiver did not show the connected state',
    );
    expect(receiver.service.currentReceiver.invitation, isNull);
    expect(receiver.service.currentReceiver.pairingCode, isNull);
    expect(await sender.transfers.getTransfers(), isEmpty);

    await expectLater(
      sender.service.connectWithInvitation(invitation),
      throwsA(isA<TransferRequestException>()),
    );

    final requestFuture = receiver.service
        .watchIncomingRequests()
        .firstWhere((requests) => requests.isNotEmpty)
        .timeout(const Duration(seconds: 8));
    final sendFuture = sender.service.sendDocumentToPeer(
      documentId: document.id,
      peerId: peer.id,
    );
    final requests = await requestFuture;

    await _waitUntil(
      () async => (await sender.transfers.getTransfers()).any(
        (task) => task.status == TransferStatus.awaitingApproval,
      ),
      reason: 'the sender did not wait for explicit receiver approval',
    );
    expect(
      receiver.service.currentReceiver.phase,
      ReceiverPhase.awaitingApproval,
    );
    expect(receiver.service.currentReceiver.documentTitle, 'QR notes');
    expect(await receiver.documents.getDocuments(), isEmpty);
    expect((await sender.transfers.getTransfers()).single.transferredBytes, 0);

    await receiver.service.approveIncoming(requests.first.transferId);
    final task = await sendFuture;
    expect(task.status, TransferStatus.completed);
    expect(task.transferredBytes, bytes.length);
    expect(task.note, contains('Receiver phone'));

    await _waitUntil(
      () => receiver.service.currentReceiver.phase == ReceiverPhase.waiting,
      reason: 'the receiver did not rotate its invitation after completion',
    );
    final refreshed = receiver.service.currentReceiver;
    expect(refreshed.invitation, isNotNull);
    expect(refreshed.invitation!.token, isNot(invitation.token));
    expect(refreshed.invitation!.sessionId, invitation.sessionId);
    expect(refreshed.statusMessage, contains('Received'));
    expect(phases, contains(ReceiverPhase.connected));
    expect(phases, contains(ReceiverPhase.awaitingApproval));
    expect(phases, contains(ReceiverPhase.transferring));
    expect(phases, contains(ReceiverPhase.waiting));

    final received = await receiver.documents.findBySha256(_hashBytes(bytes));
    expect(received, isNotNull);
    expect(received!.title, 'QR notes');
    expect(await receiver.documents.getDocuments(), hasLength(1));
    expect(
      (await sender.transfers.getTransfers()).first.status,
      TransferStatus.completed,
    );

    await expectLater(
      sender.service.connectWithInvitation(invitation),
      throwsA(isA<TransferRequestException>()),
    );
    final senderTask = (await sender.transfers.getTransfers()).single;
    final receiverTask = (await receiver.transfers.getTransfers()).single;
    expect(senderTask.toString(), isNot(contains(invitation.token)));
    expect(receiverTask.toString(), isNot(contains(invitation.token)));
    expect(refreshed.statusMessage, isNot(contains(invitation.token)));
    expect(await sender.transfers.getTransfers(), hasLength(1));
  });

  test('rotates the manual pairing code after five failed attempts', () async {
    final sender = await _Device.create(name: 'Code sender');
    final receiver = await _Device.create(name: 'Code receiver');
    final approver = _AutoApprover();
    addTearDown(() async {
      await approver.dispose();
      await sender.dispose();
      await receiver.dispose();
    });

    final bytes = _pdfBytes('pairing lockout');
    final document = await sender.addDocument(
      fileName: 'Pairing notes.pdf',
      bytes: bytes,
      format: DocumentFormat.pdf,
      title: 'Pairing notes',
    );
    final endpoint = await receiver.service.startReceiving();
    final firstCode = endpoint.pairingCode;
    expect(firstCode, matches(RegExp(r'^\d{6}$')));
    final wrongCode = firstCode == '000000' ? '111111' : '000000';

    for (var attempt = 0; attempt < 4; attempt++) {
      final task = await sender.service.sendDocument(
        documentId: document.id,
        host: _loopback,
        port: endpoint.port!,
        pairingCode: wrongCode,
      );
      expect(task.status, TransferStatus.failed);
      expect(receiver.service.currentReceiver.pairingCode, firstCode);
    }

    final locked = await sender.service.sendDocument(
      documentId: document.id,
      host: _loopback,
      port: endpoint.port!,
      pairingCode: wrongCode,
    );
    expect(locked.status, TransferStatus.failed);
    expect(locked.failureReason, contains('Too many incorrect pairing'));

    final rotated = receiver.service.currentReceiver;
    expect(rotated.phase, ReceiverPhase.waiting);
    expect(rotated.pairingCode, isNotNull);
    expect(rotated.pairingCode, isNot(firstCode));
    expect(rotated.statusMessage, contains('Too many incorrect pairing codes'));

    approver.start(receiver.service);
    final task = await sender.service.sendDocument(
      documentId: document.id,
      host: _loopback,
      port: endpoint.port!,
      pairingCode: rotated.pairingCode!,
    );
    expect(task.status, TransferStatus.completed);
    expect(approver.seenIds, hasLength(1));
    expect(await receiver.documents.getDocuments(), hasLength(1));
  });

  test('QR connection tries each advertised address without exposing the '
      'credential', () async {
    final sender = await _Device.create(
      name: 'Sender phone',
      limits: _limits.copyWith(
        connectTimeout: const Duration(milliseconds: 300),
      ),
    );
    final receiver = await _Device.create(name: 'Receiver phone');
    addTearDown(() async {
      await sender.dispose();
      await receiver.dispose();
    });

    final endpoint = await receiver.service.startReceiving();
    final invitation = TransferInvitation.parse(
      endpoint.invitation!.payload,
    ).withAddresses(const ['192.0.2.1', _loopback]);
    final peer = await sender.service.connectWithInvitation(invitation);
    expect(peer.address, _loopback);
    expect(peer.deviceName, 'Receiver phone');
    expect(peer.toString(), isNot(contains(invitation.token)));
    expect(invitation.toString(), isNot(contains(invitation.token)));

    await sender.service.disconnectPeer(peer.id);
    await _waitUntil(
      () => receiver.service.currentReceiver.phase == ReceiverPhase.waiting,
      reason: 'the receiver did not release the verified peer connection',
    );
    expect(receiver.service.currentReceiver.invitation, isNotNull);
    expect(
      receiver.service.currentReceiver.invitation!.token,
      isNot(invitation.token),
    );
  });

  test('expired invitations are refreshed automatically and old credentials '
      'are rejected', () async {
    final receiver = await _Device.create(
      name: 'Receiver phone',
      limits: _limits.copyWith(
        invitationTtl: const Duration(milliseconds: 700),
      ),
    );
    addTearDown(receiver.dispose);

    final endpoint = await receiver.service.startReceiving();
    final oldInvitation = endpoint.invitation;
    expect(oldInvitation, isNotNull);

    await _waitUntil(
      () {
        final current = receiver.service.currentReceiver;
        return current.phase == ReceiverPhase.waiting &&
            current.invitation != null &&
            current.invitation!.token != oldInvitation!.token;
      },
      timeout: const Duration(seconds: 5),
      reason: 'the receiver did not replace the expired invitation',
    );
    final refreshed = receiver.service.currentReceiver;
    expect(refreshed.invitation!.sessionId, oldInvitation!.sessionId);
    expect(refreshed.statusMessage, contains('expired'));
    expect(oldInvitation.isExpiredAt(DateTime.now()), isTrue);

    final socket = await Socket.connect(
      _loopback,
      endpoint.port!,
      timeout: const Duration(seconds: 5),
    );
    final connection = TransferConnection(socket, _limits);
    addTearDown(connection.close);
    await connection.writeMessage(
      HelloMessage(
        peerName: 'Old sender',
        sessionId: oldInvitation.sessionId,
        invitationToken: oldInvitation.token,
      ),
    );
    final error = await connection.readMessage(
      timeout: const Duration(seconds: 5),
    );
    expect(error, isA<ErrorMessage>());
    expect(
      (error as ErrorMessage).code,
      anyOf('invitation_used', 'invitation_expired'),
    );
    expect(receiver.service.currentReceiver.phase, ReceiverPhase.waiting);
    expect(await receiver.transfers.getTransfers(), isEmpty);
  });

  test('stopping receive mode invalidates its invitation', () async {
    final sender = await _Device.create(name: 'Sender phone');
    final receiver = await _Device.create(name: 'Receiver phone');
    addTearDown(() async {
      await sender.dispose();
      await receiver.dispose();
    });

    final endpoint = await receiver.service.startReceiving();
    final invitation = _loopbackInvitation(endpoint);
    await receiver.service.stopReceiving();
    expect(receiver.service.currentReceiver.isListening, isFalse);
    expect(receiver.service.currentReceiver.phase, ReceiverPhase.idle);
    await expectLater(
      receiver.service.refreshInvitation(),
      throwsA(isA<TransferRequestException>()),
    );
    await expectLater(
      sender.service.connectWithInvitation(invitation),
      throwsA(isA<TransferRequestException>()),
    );
    expect(await sender.transfers.getTransfers(), isEmpty);
  });

  test('startup recovery fails unfinished rows and removes abandoned '
      'temporary files', () async {
    final device = await _Device.create(name: 'Restarted phone');
    addTearDown(device.dispose);
    await device.temporaryDirectory.create(recursive: true);
    final stale = File(p.join(device.temporaryDirectory.path, 'stale.part'));
    await stale.writeAsBytes(_pdfBytes('stale'));
    final now = DateTime.now();
    await device.transfers.create(
      TransferDraft(
        id: 'rx-stale',
        direction: TransferDirection.receive,
        documentTitle: 'Stale document',
        fileTypeLabel: 'PDF',
        sizeBytes: 100,
        peerName: 'Old sender',
        status: TransferStatus.transferring,
        createdAt: now,
        tempFileName: 'stale.part',
      ),
    );

    await device.service.recoverIncompleteTransfers();
    final task = await device.transfers.findById('rx-stale');
    expect(task?.status, TransferStatus.failed);
    expect(task?.failureReason, contains('closed'));
    expect(task?.isTerminal, isTrue);
    expect(await stale.exists(), isFalse);
    expect(await device.temporaryDirectory.list().toList(), isEmpty);
  });
}
