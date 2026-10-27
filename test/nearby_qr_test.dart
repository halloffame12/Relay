import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:relay/app/theme/app_theme.dart';
import 'package:relay/features/library/application/library_providers.dart';
import 'package:relay/features/library/domain/document.dart';
import 'package:relay/features/nearby/application/share_intent_provider.dart';
import 'package:relay/features/nearby/presentation/qr_scanner_screen.dart';
import 'package:relay/features/nearby/presentation/qr_send_screen.dart';
import 'package:relay/features/transfers/domain/transfer_invitation.dart';
import 'package:relay/features/transfers/domain/transfer_service.dart';

import 'support/test_harness.dart';

final _sessionId = 'a' * relayInvitationSessionLength;
final _token = 'b' * relayInvitationTokenLength;

TransferInvitation _invitation() {
  final now = DateTime.now();
  return TransferInvitation.validated(
    sessionId: _sessionId,
    token: _token,
    addresses: const ['192.168.1.42'],
    port: 40404,
    expiresAt: now.add(const Duration(minutes: 5)),
    now: now,
  );
}

Future<TestHarness> _pumpApp(
  WidgetTester tester, {
  ReceiverEndpoint receiver = const ReceiverEndpoint.idle(),
  TransferService? transferService,
  bool seed = true,
}) async {
  final harness = (await tester.runAsync(
    () => TestHarness.create(seed: seed),
  ))!;
  addTearDown(() => tester.runAsync(harness.dispose));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  await tester.pumpWidget(
    await harness.buildApp(
      receiver: receiver,
      transferService: transferService,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
  return harness;
}

Future<void> _openNearby(WidgetTester tester) async {
  await tester.tap(find.text('Nearby').first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
}

void main() {
  testWidgets(
    'waiting receiver renders a QR and keeps manual details secondary',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final invitation = _invitation();
      await _pumpApp(
        tester,
        receiver: ReceiverEndpoint(
          isListening: true,
          port: invitation.port,
          pairingCode: '123456',
          addresses: invitation.addresses,
          invitation: invitation,
        ),
      );
      await _openNearby(tester);

      expect(find.text('Ready to receive'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text(invitation.payload), findsNothing);
      expect(find.textContaining(invitation.token), findsNothing);
      expect(find.text('123456'), findsNothing);

      final manualButton = find.text('Manual connection details');
      await tester.ensureVisible(manualButton);
      await tester.pump();
      await tester.tap(manualButton);
      await tester.pump();

      expect(find.text('123456'), findsOneWidget);
      expect(find.text('192.168.1.42:40404'), findsOneWidget);
      expect(find.text('Hide manual connection details'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('connected receiver never shows a stale QR or pairing code', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      receiver: const ReceiverEndpoint(
        isListening: true,
        port: 40404,
        addresses: ['192.168.1.42'],
        phase: ReceiverPhase.connected,
        peerName: 'Sender phone',
      ),
    );
    await _openNearby(tester);

    expect(find.text('Sender connected'), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);
    expect(find.text('123456'), findsNothing);
    expect(find.textContaining('Manual connection details'), findsNothing);
  });

  testWidgets('scanner delivers one valid invitation and ignores duplicates', (
    tester,
  ) async {
    final invitation = _invitation();
    final received = <TransferInvitation>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: QrScannerScreen(
          onInvitation: received.add,
          scannerBuilder: (context, onDetect) => Center(
            child: FilledButton(
              onPressed: () {
                onDetect(invitation.payload);
                onDetect(invitation.payload);
              },
              child: const Text('Simulate scan'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Simulate scan'));
    await tester.pump();

    expect(received, hasLength(1));
    expect(received.single.sessionId, invitation.sessionId);
    expect(received.single.token, invitation.token);
    expect(find.text('Scan receiver code'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scanner rejects a URL and can retry without opening it', (
    tester,
  ) async {
    var delivered = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: QrScannerScreen(
          onInvitation: (_) => delivered++,
          scannerBuilder: (context, onDetect) => Center(
            child: FilledButton(
              onPressed: () => onDetect('https://example.com/receiver'),
              child: const Text('Simulate bad scan'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Simulate bad scan'));
    await tester.pump();

    expect(delivered, 0);
    expect(find.text('Code not accepted'), findsOneWidget);
    expect(find.textContaining('not a Relay'), findsOneWidget);
    expect(find.text('Scan again'), findsOneWidget);
    expect(find.text('Use manual connection'), findsOneWidget);

    await tester.tap(find.text('Scan again'));
    await tester.pump();
    expect(find.text('Code not accepted'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('camera denial explains the Settings path and offers a retry', (
    tester,
  ) async {
    var retries = 0;
    var manual = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: CameraErrorPanel(
            error: const MobileScannerException(
              errorCode: MobileScannerErrorCode.permissionDenied,
            ),
            onRetry: () => retries++,
            onManual: () => manual++,
          ),
        ),
      ),
    );

    expect(find.text('Camera access is off'), findsOneWidget);
    expect(
      find.textContaining('Settings > Apps > Relay > Permissions > Camera'),
      findsOneWidget,
    );
    await tester.tap(find.text('Try camera again'));
    await tester.pump();
    expect(retries, 1);

    await tester.tap(find.text('Use manual connection'));
    await tester.pump();
    expect(manual, 1);
  });

  test('camera retry keeps the denial when Android stops reporting it', () {
    const denied = MobileScannerException(
      errorCode: MobileScannerErrorCode.permissionDenied,
    );

    expect(
      resolveCameraRetryError(
        previousError: denied,
        startFailure: null,
        stateError: null,
        isRunning: false,
        isStarting: false,
      ),
      same(denied),
    );
    expect(
      resolveCameraRetryError(
        previousError: denied,
        startFailure: null,
        stateError: null,
        isRunning: true,
        isStarting: false,
      ),
      isNull,
    );
    expect(
      resolveCameraRetryError(
        previousError: denied,
        startFailure: null,
        stateError: null,
        isRunning: false,
        isStarting: true,
      ),
      isNull,
    );

    const generic = MobileScannerException(
      errorCode: MobileScannerErrorCode.genericError,
    );
    expect(
      resolveCameraRetryError(
        previousError: denied,
        startFailure: generic,
        stateError: null,
        isRunning: false,
        isStarting: false,
      ),
      same(generic),
    );
  });

  testWidgets('send screen connects, selects a managed document, and sends', (
    tester,
  ) async {
    final harness = (await tester.runAsync(
      () => TestHarness.create(seed: true),
    ))!;
    addTearDown(() => tester.runAsync(harness.dispose));
    final fake = FakeTransferService();
    final invitation = _invitation();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              QrSendScreen(invitation: invitation, service: fake),
        ),
        GoRoute(
          path: '/transfers',
          builder: (context, state) =>
              const Scaffold(body: Text('Transfers page')),
        ),
        GoRoute(
          path: '/nearby/scan',
          builder: (context, state) =>
              const Scaffold(body: Text('Scanner page')),
        ),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          documentsProvider.overrideWith(
            (ref) => Stream.value([harness.epubDocument]),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Connected to Receiver phone'), findsOneWidget);
    expect(find.text('Direct address 192.168.1.20:40404'), findsOneWidget);
    expect(find.text('Choose a document to send'), findsOneWidget);
    expect(find.textContaining(invitation.token), findsNothing);
    expect(fake.connectedInvitations, hasLength(1));
    expect(fake.connectedInvitations.single.sessionId, invitation.sessionId);
    expect(fake.connectedInvitations.single.token, invitation.token);

    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('The Quiet Orchard').last);
    await tester.pumpAndSettle();

    expect(find.text('Send to Receiver phone'), findsOneWidget);
    await tester.tap(find.text('Send to Receiver phone'));
    await tester.pumpAndSettle();
    expect(find.text('Send to Receiver phone?'), findsOneWidget);
    expect(find.textContaining('192.168.1.20:40404'), findsWidgets);
    expect(find.textContaining(invitation.token), findsNothing);

    await tester.tap(find.text('Send document'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.text('Transfers page'), findsOneWidget);
    expect(fake.peerSendCalls, hasLength(1));
    expect(fake.peerSendCalls.single, '${harness.epubDocument.id}@peer-1');
    expect(fake.disconnectedPeerIds, isEmpty);
  });

  testWidgets('a transfer failure stays visible after navigating away', (
    tester,
  ) async {
    final harness = (await tester.runAsync(
      () => TestHarness.create(seed: true),
    ))!;
    addTearDown(() => tester.runAsync(harness.dispose));
    final fake = FakeTransferService(
      transferError: const TransferRequestException(
        'The receiving device closed the connection.',
      ),
    );
    final container = ProviderContainer(
      overrides: [
        documentsProvider.overrideWith(
          (ref) => Stream.value([harness.epubDocument]),
        ),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(shareIntentProvider.notifier)
        .setDocument(harness.epubDocument.id);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              QrSendScreen(invitation: _invitation(), service: fake),
        ),
        GoRoute(
          path: '/transfers',
          builder: (context, state) =>
              const Scaffold(body: Text('Transfers page')),
        ),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Send to Receiver phone'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send document'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.text('Transfers page'), findsOneWidget);
    expect(
      find.text('The receiving device closed the connection.'),
      findsOneWidget,
    );
  });

  testWidgets('connected send screen fits 320dp at larger text scaling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final harness = (await tester.runAsync(
      () => TestHarness.create(seed: true),
    ))!;
    addTearDown(() => tester.runAsync(harness.dispose));
    final container = ProviderContainer(
      overrides: [
        documentsProvider.overrideWith(
          (ref) => Stream.value([harness.epubDocument]),
        ),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(shareIntentProvider.notifier)
        .setDocument(harness.epubDocument.id);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => QrSendScreen(
            invitation: _invitation(),
            service: FakeTransferService(),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Connected to Receiver phone'), findsOneWidget);
    expect(find.text('Send to Receiver phone'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'send screen reports a failed invitation and keeps manual fallback',
    (tester) async {
      final fake = FakeTransferService(
        connectError: const TransferRequestException(
          'This QR code has already been used.',
        ),
      );
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                QrSendScreen(invitation: _invitation(), service: fake),
          ),
          GoRoute(
            path: '/nearby/scan',
            builder: (context, state) =>
                const Scaffold(body: Text('Scanner page')),
          ),
        ],
      );
      addTearDown(router.dispose);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            documentsProvider.overrideWith(
              (ref) => Stream.value(const <Document>[]),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Connection not ready'), findsOneWidget);
      expect(find.text('This QR code has already been used.'), findsOneWidget);
      expect(find.text('Scan another code'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Manual'), findsOneWidget);
      expect(find.text('Choose a document to send'), findsNothing);
    },
  );

  testWidgets('leaving a connected send screen releases the prepared peer', (
    tester,
  ) async {
    final fake = FakeTransferService();
    final invitation = _invitation();
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.push('/send'),
                child: const Text('Open send'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/send',
          builder: (context, state) =>
              QrSendScreen(invitation: invitation, service: fake),
        ),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          documentsProvider.overrideWith(
            (ref) => Stream.value(const <Document>[]),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.tap(find.text('Open send'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Connected to Receiver phone'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Open send'), findsOneWidget);
    expect(fake.disconnectedPeerIds, ['peer-1']);
  });
}
