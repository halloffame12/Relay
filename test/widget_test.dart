import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay/features/reader/domain/reading_progress.dart';
import 'package:relay/features/transfers/domain/transfer_manifest.dart';
import 'package:relay/features/transfers/domain/transfer_service.dart';
import 'package:relay/features/transfers/domain/transfer_task.dart';

import 'support/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TestHarness> pumpApp(
    WidgetTester tester, {
    bool seed = true,
    List<TransferTask> transfers = const [],
    ReceiverEndpoint receiver = const ReceiverEndpoint.idle(),
    List<IncomingTransferRequest> incomingRequests = const [],
  }) async {
    final created = await tester.runAsync(() => TestHarness.create(seed: seed));
    final harness = created!;
    addTearDown(() => tester.runAsync(harness.dispose));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
    await tester.pumpWidget(
      await harness.buildApp(
        transfers: transfers,
        receiver: receiver,
        incomingRequests: incomingRequests,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    return harness;
  }

  Future<void> openDocument(
    WidgetTester tester,
    String title, {
    bool openReader = false,
  }) async {
    final finder = find.text(title).last;
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    if (!openReader) return;
    final readButton = find.byType(FilledButton).first;
    await tester.ensureVisible(readButton);
    await tester.pump();
    await tester.tap(readButton);
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
  }

  testWidgets('opens an empty library and moves between all destinations', (
    tester,
  ) async {
    await pumpApp(tester, seed: false);

    expect(find.text('Your library'), findsOneWidget);
    expect(find.text('Your library is empty'), findsOneWidget);

    await tester.tap(find.text('Nearby').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('Offer to receive'), findsWidgets);
    expect(find.text('Same Wi-Fi required'), findsOneWidget);
    expect(find.text('Campus Phone'), findsNothing);

    await tester.tap(find.text('Transfers').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('No transfers yet'), findsOneWidget);
    expect(find.text('Both devices must be on the same Wi-Fi'), findsOneWidget);

    await tester.tap(find.text('Settings').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Reading'), findsOneWidget);
    expect(find.text('RELAY STORAGE'), findsOneWidget);

    await tester.tap(find.text('Library').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Your library'), findsOneWidget);
  });

  testWidgets('nearby shows exact receive details and fits a 320dp screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(
      tester,
      receiver: const ReceiverEndpoint(
        isListening: true,
        port: 40404,
        pairingCode: '123456',
        addresses: ['192.168.1.42'],
      ),
    );

    await tester.tap(find.text('Nearby').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Ready to receive'), findsOneWidget);
    expect(find.text('123456'), findsOneWidget);
    expect(find.text('192.168.1.42:40404'), findsOneWidget);
    expect(find.text('Stop receiving'), findsOneWidget);
    expect(find.text('Campus Phone'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('transfers renders real persisted states and byte counts', (
    tester,
  ) async {
    final now = DateTime.now();
    final tasks = [
      TransferTask(
        id: 'tx-active',
        documentId: 'doc-1',
        documentTitle: 'Active document',
        fileTypeLabel: 'PDF',
        sizeBytes: 1000,
        direction: TransferDirection.send,
        deviceName: 'Pixel receiver',
        status: TransferStatus.transferring,
        createdAt: now,
        updatedAt: now,
        transferredBytes: 500,
      ),
      TransferTask(
        id: 'tx-done',
        documentId: null,
        documentTitle: 'Completed document',
        fileTypeLabel: 'EPUB',
        sizeBytes: 2048,
        direction: TransferDirection.receive,
        deviceName: 'Pixel sender',
        status: TransferStatus.completed,
        createdAt: now,
        updatedAt: now,
        transferredBytes: 2048,
        completedAt: now,
        note: 'Added to your library as “Completed document”.',
      ),
      TransferTask(
        id: 'tx-failed',
        documentId: null,
        documentTitle: 'Interrupted document',
        fileTypeLabel: 'PDF',
        sizeBytes: 1000,
        direction: TransferDirection.send,
        deviceName: 'Pixel receiver',
        status: TransferStatus.failed,
        createdAt: now,
        updatedAt: now,
        transferredBytes: 300,
        failureReason: 'The connection was lost. Nothing was imported.',
      ),
      TransferTask(
        id: 'tx-cancelled',
        documentId: null,
        documentTitle: 'Cancelled document',
        fileTypeLabel: 'PDF',
        sizeBytes: 1000,
        direction: TransferDirection.receive,
        deviceName: 'Pixel sender',
        status: TransferStatus.cancelled,
        createdAt: now,
        updatedAt: now,
        transferredBytes: 120,
        note: 'You declined this transfer.',
      ),
    ];
    await pumpApp(tester, transfers: tasks);

    await tester.tap(find.text('Transfers').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Active document'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Completed document'), findsOneWidget);
    expect(find.text('Interrupted document'), findsOneWidget);
    expect(find.text('Cancelled document'), findsOneWidget);
    expect(find.text('Interrupted or cancelled'), findsOneWidget);
    expect(
      find.text('The connection was lost. Nothing was imported.'),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('incoming transfer approval is a blocking global dialog', (
    tester,
  ) async {
    final request = IncomingTransferRequest(
      transferId: 'rx-test',
      manifest: TransferManifest.validated(
        fileName: 'incoming.pdf',
        title: 'Incoming document',
        format: 'pdf',
        sizeBytes: 2048,
        sha256:
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        maxBytes: 100 * 1024 * 1024,
      ),
      peerName: 'Sender phone',
    );
    await pumpApp(tester, incomingRequests: [request]);

    expect(find.text('Receive this document?'), findsOneWidget);
    expect(find.text('Incoming document'), findsOneWidget);
    expect(find.text('From Sender phone'), findsOneWidget);

    await tester.tap(find.text('Reject'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Receive this document?'), findsNothing);
    expect(find.text('Incoming transfer rejected.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('library shows the real imported documents and storage count', (
    tester,
  ) async {
    final harness = await pumpApp(tester);

    expect(find.text('The Quiet Orchard'), findsWidgets);
    expect(find.text('Designing for Attention'), findsWidgets);
    expect(find.textContaining('2 documents'), findsWidgets);
    expect(harness.pdfDocument.pageCount, 3);

    await tester.tap(find.text('Settings').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('RELAY STORAGE'), findsOneWidget);
    expect(find.textContaining('2 documents'), findsWidgets);
  });

  testWidgets('missing managed files disable reading and explain removal', (
    tester,
  ) async {
    final harness = (await tester.runAsync(() => TestHarness.create()))!;
    addTearDown(() => tester.runAsync(harness.dispose));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
    await tester.pumpWidget(
      await harness.buildApp(
        documents: [
          harness.epubDocument.copyWith(isMissing: true),
          harness.pdfDocument,
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    await openDocument(tester, 'The Quiet Orchard');

    expect(find.text('File missing'), findsWidgets);
    expect(
      find.textContaining('original file you imported is not affected'),
      findsOneWidget,
    );
    final readButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'File missing'),
    );
    expect(readButton.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('library renders without overflow on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Your library'), findsOneWidget);

    for (final destination in ['Nearby', 'Transfers', 'Settings']) {
      await tester.tap(find.text(destination).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      expect(
        tester.takeException(),
        isNull,
        reason: '$destination should not overflow at 320 logical pixels.',
      );
    }
  });

  testWidgets('library tolerates larger text scaling', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpApp(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Your library'), findsOneWidget);
  });

  testWidgets('wide layouts use the navigation rail', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester, seed: false);

    expect(find.byTooltip('Import a document'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('real EPUB details and reader render on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);
    await openDocument(tester, 'The Quiet Orchard');
    expect(find.text('Document details'), findsWidgets);
    expect(tester.takeException(), isNull);

    final readButton = find.byType(FilledButton).first;
    await tester.ensureVisible(readButton);
    await tester.pump();
    await tester.tap(readButton);
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 50));

    expect(find.byTooltip('Back to document'), findsWidgets);
    expect(find.text('Attention'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pdf reader renders on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);
    await openDocument(tester, 'Designing for Attention', openReader: true);

    expect(find.byTooltip('Next page'), findsWidgets);
    expect(find.textContaining('Page 1 of 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reader and details tolerate 1.3 text scaling at 320dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpApp(tester);
    await openDocument(tester, 'The Quiet Orchard', openReader: true);
    expect(tester.takeException(), isNull);
  });

  testWidgets('EPUB reader restores the last chapter before opening', (
    tester,
  ) async {
    final harness = (await tester.runAsync(() => TestHarness.create()))!;
    addTearDown(() => tester.runAsync(harness.dispose));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
    await tester.pumpWidget(
      await harness.buildApp(
        progress: {
          harness.epubDocument.id: ReadingProgress(
            documentId: harness.epubDocument.id,
            fraction: 0.6,
            locationIndex: 1,
            lastReadAt: DateTime.now(),
          ),
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    await openDocument(tester, 'The Quiet Orchard', openReader: true);

    expect(find.text('The Orchard'), findsWidgets);
    expect(find.text('Attention'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a short final EPUB chapter is marked complete', (tester) async {
    tester.view.physicalSize = const Size(1080, 2344);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);
    await openDocument(tester, 'The Quiet Orchard', openReader: true);

    final nextChapter = find.text('Next chapter');
    expect(nextChapter, findsOneWidget);
    await tester.ensureVisible(nextChapter);
    await tester.pump();
    await tester.tap(nextChapter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('100%'), findsOneWidget);
    expect(find.textContaining('Chapter 2 of 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('import screen renders on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester, seed: false);

    await tester.tap(find.byTooltip('Import a document'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Import a document'), findsWidgets);
    expect(find.text('Choose a file'), findsOneWidget);
    expect(find.textContaining('Files are checked'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
