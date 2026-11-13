import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:relay/features/library/domain/document.dart';
import 'package:relay/features/share/data/share_service.dart';
import 'package:relay/features/share/domain/share_invitation.dart';
import 'package:relay/features/share/domain/share_state.dart';

import 'support/share_test_support.dart';

void main() {
  late ShareTestHarness harness;

  setUp(() async {
    harness = await ShareTestHarness.create();
    addTearDown(() async => harness.dispose());
  });

  Future<ShareInvitation> startSender(List<String> documentIds) async {
    await harness.service.startSender(documentIds);
    final invitation = harness.service.sender.invitation;
    expect(invitation, isNotNull);
    return invitation!;
  }

  test('sends a file over the injected direct link and verifies it', () async {
    final payload = List<int>.generate(10000, (index) => index % 251);
    final document = await harness.addDocument(
      id: 'doc-1',
      fileName: 'field-notes.pdf',
      bytes: payload,
    );

    final invitation = await startSender([document.id]);
    final receive = harness.service.join(invitation);

    await waitFor(
      () => harness.service.receiver.phase == SharePhase.awaitingApproval,
    );
    expect(harness.service.receiver.senderName, 'Test sender');
    expect(harness.service.receiver.offer!.fileCount, 1);
    expect(harness.service.receiver.offer!.totalBytes, payload.length);
    expect(harness.handler.imported, isEmpty);

    await harness.service.approveIncoming();
    await receive;
    await waitFor(() => harness.service.sender.phase == SharePhase.completed);

    expect(harness.service.receiver.phase, SharePhase.completed);
    expect(
      harness.service.receiver.results.single.status,
      ShareResultStatus.imported,
    );
    expect(
      harness.service.sender.results.single.status,
      ShareResultStatus.imported,
    );
    expect(harness.service.sender.peerName, 'Test sender');

    expect(harness.handler.imported.single.fileName, 'field-notes.pdf');
    expect(harness.handler.importedBytes.single, payload);
    expect(harness.handler.transportLabels.single, 'Direct connection');

    final stored = File(
      '${harness.libraryDirectory.path}${Platform.pathSeparator}'
      '1-field-notes.pdf',
    );
    expect(await stored.readAsBytes(), payload);

    final leftovers = await harness.temporaryDirectory
        .list()
        .where((entity) => entity.path.endsWith('.part'))
        .toList();
    expect(leftovers, isEmpty);
  });

  test('a rejection cancels both sides and imports nothing', () async {
    final document = await harness.addDocument(
      id: 'doc-1',
      fileName: 'book.pdf',
      bytes: List<int>.filled(64, 7),
    );

    final invitation = await startSender([document.id]);
    final receive = harness.service.join(invitation);
    await waitFor(
      () => harness.service.receiver.phase == SharePhase.awaitingApproval,
    );

    await harness.service.rejectIncoming();
    await receive;
    await waitFor(() => harness.service.sender.phase == SharePhase.cancelled);

    expect(harness.service.receiver.phase, SharePhase.cancelled);
    expect(harness.handler.imported, isEmpty);
    expect(harness.service.sender.message, contains('declined'));
  });

  test(
    'a corrupted data frame fails the checksum and imports nothing',
    () async {
      final document = await harness.addDocument(
        id: 'doc-1',
        fileName: 'integrity.pdf',
        bytes: List<int>.generate(5000, (index) => index % 255),
      );

      final invitation = await startSender([document.id]);
      final senderLink = harness.connector.senderLink!;
      senderLink.onAdd = (bytes) {
        if (bytes.isEmpty || bytes[0] != 2) return bytes;
        final copy = Uint8List.fromList(bytes);
        copy[copy.length - 1] ^= 0xFF;
        return copy;
      };

      final receive = harness.service.join(invitation);
      await waitFor(
        () => harness.service.receiver.phase == SharePhase.awaitingApproval,
      );
      await harness.service.approveIncoming();

      await receive;
      await waitFor(() => harness.service.sender.phase == SharePhase.failed);

      expect(harness.service.receiver.phase, SharePhase.failed);
      expect(harness.service.receiver.message, contains('checksum'));
      expect(harness.handler.imported, isEmpty);

      final leftovers = await harness.temporaryDirectory
          .list()
          .where((entity) => entity.path.endsWith('.part'))
          .toList();
      expect(leftovers, isEmpty);
    },
  );

  test('a duplicate is verified but not imported twice', () async {
    final bytes = List<int>.filled(128, 3);
    final document = await harness.addDocument(
      id: 'doc-1',
      fileName: 'repeat.pdf',
      bytes: bytes,
    );

    final invitation = await startSender([document.id]);
    final receive = harness.service.join(invitation);
    await waitFor(
      () => harness.service.receiver.phase == SharePhase.awaitingApproval,
    );
    await harness.service.approveIncoming();
    await receive;
    await waitFor(() => harness.service.sender.phase == SharePhase.completed);

    expect(
      harness.service.receiver.results.single.status,
      ShareResultStatus.imported,
    );

    // Run a second session with the same bytes so the handler reports a
    // duplicate instead of importing another copy.
    await harness.service.resetSender();
    await harness.service.resetReceiver();
    harness.handler.markExisting(document.sha256!);

    final second = await startSender([document.id]);
    final secondReceive = harness.service.join(second);
    await waitFor(
      () => harness.service.receiver.phase == SharePhase.awaitingApproval,
    );
    await harness.service.approveIncoming();
    await secondReceive;
    await waitFor(() => harness.service.sender.phase == SharePhase.completed);

    expect(
      harness.service.receiver.results.single.status,
      ShareResultStatus.duplicate,
    );
    expect(harness.service.sender.message, contains('already had'));
    expect(harness.handler.imported, hasLength(1));
  });

  test('sends multiple files in one approved batch', () async {
    final first = await harness.addDocument(
      id: 'doc-1',
      fileName: 'first.pdf',
      bytes: List<int>.generate(2000, (index) => index % 13),
    );
    final second = await harness.addDocument(
      id: 'doc-2',
      fileName: 'second.epub',
      bytes: List<int>.generate(3000, (index) => index % 17),
      format: DocumentFormat.epub,
    );

    final invitation = await startSender([first.id, second.id]);
    final receive = harness.service.join(invitation);
    await waitFor(
      () => harness.service.receiver.phase == SharePhase.awaitingApproval,
    );
    expect(harness.service.receiver.offer!.fileCount, 2);
    expect(harness.service.receiver.offer!.totalBytes, 5000);

    await harness.service.approveIncoming();
    await receive;
    await waitFor(() => harness.service.sender.phase == SharePhase.completed);

    expect(harness.handler.imported.map((file) => file.fileName), [
      'first.pdf',
      'second.epub',
    ]);
    expect(harness.service.sender.results.map((result) => result.status), [
      ShareResultStatus.imported,
      ShareResultStatus.imported,
    ]);
    expect(harness.service.sender.message, contains('2 imported'));
  });

  test('rejects a session when the scanned token does not match', () async {
    final document = await harness.addDocument(
      id: 'doc-1',
      fileName: 'secret.pdf',
      bytes: List<int>.filled(32, 1),
    );

    final invitation = await startSender([document.id]);
    final forged = ShareInvitation.create(
      sessionId: invitation.sessionId,
      token: 'c' * shareTokenLength,
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 3)),
      senderName: invitation.senderName,
    );

    await harness.service.join(forged);
    await waitFor(() => harness.service.sender.phase == SharePhase.failed);

    expect(harness.service.receiver.phase, SharePhase.failed);
    expect(harness.handler.imported, isEmpty);
  });

  test('refuses to start with no documents or an unknown id', () async {
    await expectLater(
      harness.service.startSender(const []),
      throwsA(isA<ShareException>()),
    );
    expect(harness.service.sender.phase, SharePhase.idle);

    await expectLater(
      harness.service.startSender(const ['missing']),
      throwsA(isA<ShareException>()),
    );
    expect(harness.service.sender.phase, SharePhase.failed);
    expect(harness.service.sender.message, contains('no longer'));
  });

  test('refuses an expired invitation before connecting', () async {
    final past = DateTime.now().toUtc().subtract(const Duration(minutes: 5));
    final expired = ShareInvitation.create(
      sessionId: 'e' * shareSessionIdLength,
      token: 'f' * shareTokenLength,
      expiresAt: past.add(const Duration(minutes: 2)),
      senderName: 'Old sender',
      now: past,
    );

    await expectLater(
      harness.service.join(expired),
      throwsA(
        isA<ShareException>().having(
          (error) => error.code,
          'code',
          'expired_invitation',
        ),
      ),
    );
    expect(harness.service.receiver.phase, SharePhase.idle);
  });

  test('explains when cross-network sharing is not configured', () async {
    await harness.dispose();

    harness = await ShareTestHarness.create(crossNetwork: false);
    final document = await harness.addDocument(
      id: 'doc-1',
      fileName: 'local.pdf',
      bytes: List<int>.filled(16, 2),
    );
    final invitation = await startSender([document.id]);

    await harness.service.join(invitation);

    expect(harness.service.receiver.phase, SharePhase.failed);
    expect(harness.service.receiver.message, contains('same network'));
  });

  test('resetReceiver refuses while approval is pending', () async {
    final document = await harness.addDocument(
      id: 'doc-1',
      fileName: 'pending.pdf',
      bytes: List<int>.filled(16, 5),
    );

    final invitation = await startSender([document.id]);
    final receive = harness.service.join(invitation);
    await waitFor(
      () => harness.service.receiver.phase == SharePhase.awaitingApproval,
    );

    await expectLater(
      harness.service.resetReceiver(),
      throwsA(isA<ShareException>()),
    );

    await harness.service.rejectIncoming();
    await receive;
    await harness.service.resetReceiver();

    expect(harness.service.receiver.phase, SharePhase.idle);
    expect(harness.service.receiver.offer, isNull);
  });

  test('stopping the sender clears the invitation', () async {
    final document = await harness.addDocument(
      id: 'doc-1',
      fileName: 'stop.pdf',
      bytes: List<int>.filled(16, 9),
    );

    await startSender([document.id]);
    await harness.service.stopSender();

    expect(harness.service.sender.phase, SharePhase.idle);
    expect(harness.service.sender.invitation, isNull);
    expect(harness.service.sender.isBusy, isFalse);
  });
}
