import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:relay/app/theme/app_theme.dart';
import 'package:relay/core/widgets/relay_buttons.dart';
import 'package:relay/features/library/application/library_providers.dart';
import 'package:relay/features/library/domain/document.dart';
import 'package:relay/features/share/application/share_providers.dart';
import 'package:relay/features/share/domain/share_invitation.dart';
import 'package:relay/features/share/domain/share_offer.dart';
import 'package:relay/features/share/domain/share_state.dart';
import 'package:relay/features/share/presentation/share_home_screen.dart';
import 'package:relay/features/share/presentation/share_receive_screen.dart';
import 'package:relay/features/share/presentation/share_scanner_screen.dart';
import 'package:relay/features/share/presentation/share_send_screen.dart';
import 'package:relay/core/widgets/relay_brand_icon.dart';
import 'package:relay/features/transfers/domain/transfer_manifest.dart';

Document _document({
  required String id,
  required String title,
  required String fileName,
  int sizeBytes = 4096,
  DocumentFormat format = DocumentFormat.pdf,
  bool available = true,
}) {
  return Document(
    id: id,
    title: title,
    author: 'Mara Venn',
    source: 'Imported on this device',
    format: format,
    sizeBytes: sizeBytes,
    addedAt: DateTime(2026, 1, 1),
    description: 'A share widget fixture.',
    coverDesign: CoverDesign.minimal,
    coverPalette: CoverPalette.sage,
    fileName: fileName,
    storedFileName: available ? fileName : null,
    sha256: available ? 'a' * 64 : null,
    isImported: available,
  );
}

ShareInvitation _invitation() {
  final now = DateTime.now().toUtc();
  return ShareInvitation.create(
    sessionId: 'a' * shareSessionIdLength,
    token: 'b' * shareTokenLength,
    expiresAt: now.add(const Duration(minutes: 4)),
    senderName: 'Sender phone',
    now: now,
  );
}

ShareOffer _offer({int files = 2}) {
  return ShareOffer.validated(
    batchId: 'batch-1234567890',
    files: [
      for (var index = 0; index < files; index++)
        TransferManifest.validated(
          fileName: index == 0 ? 'field-notes.pdf' : 'second-book.epub',
          title: index == 0 ? 'Field Notes' : 'Second Book',
          format: index == 0 ? 'pdf' : 'epub',
          sizeBytes: 1024 * (index + 1),
          sha256: String.fromCharCode(97 + index) * 64,
          maxBytes: 100 * 1024 * 1024,
        ),
    ],
  );
}

Widget _app({
  required Widget home,
  List<Override> overrides = const [],
  GoRouter? router,
}) {
  final child = router == null
      ? MaterialApp(theme: AppTheme.light, home: home)
      : MaterialApp.router(theme: AppTheme.light, routerConfig: router);
  return ProviderScope(overrides: overrides, child: child);
}

List<Override> _senderState(SenderShareState state) => [
  senderShareStateProvider.overrideWith((ref) => Stream.value(state)),
  receiverShareStateProvider.overrideWith(
    (ref) => Stream.value(const ReceiverShareState.idle()),
  ),
];

List<Override> _receiverState(ReceiverShareState state) => [
  receiverShareStateProvider.overrideWith((ref) => Stream.value(state)),
  senderShareStateProvider.overrideWith(
    (ref) => Stream.value(const SenderShareState.idle()),
  ),
];

Future<void> _disposeScreen(WidgetTester tester) async {
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShareHomeScreen', () {
    testWidgets('renders the two entry points and the nearby-only notice', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/nearby',
        routes: [
          GoRoute(path: '/nearby', builder: (_, _) => const ShareHomeScreen()),
          GoRoute(
            path: '/library',
            builder: (_, _) => const Scaffold(body: Text('Library page')),
          ),
          GoRoute(
            path: '/nearby/send',
            builder: (_, _) => const Scaffold(body: Text('Send page')),
          ),
          GoRoute(
            path: '/nearby/receive',
            builder: (_, _) => const Scaffold(body: Text('Receive page')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await _disposeScreen(tester);

      await tester.pumpWidget(
        _app(
          home: const SizedBox.shrink(),
          router: router,
          overrides: [
            ..._senderState(const SenderShareState.idle()),
            shareCrossNetworkConfiguredProvider.overrideWithValue(false),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Send & receive'), findsOneWidget);
      expect(find.text('Send documents'), findsOneWidget);
      expect(find.text('Receive documents'), findsOneWidget);
      expect(find.text('Nearby transfers only in this build'), findsOneWidget);
      expect(find.text('NEARBY NETWORKS'), findsOneWidget);
      expect(find.byType(RelayBrandIcon), findsOneWidget);

      await tester.tap(find.text('Send documents'));
      await tester.pumpAndSettle();
      expect(find.text('Send page'), findsOneWidget);
    });

    testWidgets('explains the relay fallback when signaling is configured', (
      tester,
    ) async {
      await _disposeScreen(tester);
      await tester.pumpWidget(
        _app(
          home: const ShareHomeScreen(),
          overrides: [
            ..._senderState(const SenderShareState.idle()),
            shareCrossNetworkConfiguredProvider.overrideWithValue(true),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('ANY NETWORK'), findsOneWidget);
      expect(find.text('Direct, with a relay fallback'), findsOneWidget);
    });

    testWidgets('an active sender session is surfaced on the home screen', (
      tester,
    ) async {
      await _disposeScreen(tester);
      await tester.pumpWidget(
        _app(
          home: const ShareHomeScreen(),
          overrides: _senderState(
            SenderShareState(
              phase: SharePhase.waiting,
              invitation: _invitation(),
              fileCount: 1,
              totalBytes: 4096,
              message: 'Waiting for a device to scan the QR code.',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Sending in progress'), findsOneWidget);
      expect(
        find.text('Waiting for a device to scan the QR code.'),
        findsOneWidget,
      );
    });
  });

  group('ShareSendScreen', () {
    testWidgets('lists only managed files and enables the QR step on select', (
      tester,
    ) async {
      await _disposeScreen(tester);
      await tester.pumpWidget(
        _app(
          home: const ShareSendScreen(),
          overrides: [
            ..._senderState(const SenderShareState.idle()),
            documentsProvider.overrideWith(
              (ref) => Stream.value([
                _document(
                  id: 'doc-1',
                  title: 'Field Notes',
                  fileName: 'field-notes.pdf',
                ),
                _document(
                  id: 'doc-2',
                  title: 'Second Book',
                  fileName: 'second-book.epub',
                  format: DocumentFormat.epub,
                ),
                _document(
                  id: 'doc-3',
                  title: 'Missing Copy',
                  fileName: 'missing.pdf',
                  available: false,
                ),
              ]),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Choose documents'), findsOneWidget);
      expect(find.text('Field Notes'), findsWidgets);
      expect(find.text('Second Book'), findsWidgets);
      expect(find.text('Missing Copy'), findsNothing);
      expect(find.text('No documents selected'), findsOneWidget);

      final button = find.widgetWithText(RelayButton, 'Show QR code');
      expect(tester.widget<RelayButton>(button).onPressed, isNull);

      await tester.tap(find.text('Field Notes').first);
      await tester.pump();

      expect(find.text('1 document'), findsOneWidget);
      expect(tester.widget<RelayButton>(button).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the QR with an expiry and never renders hints', (
      tester,
    ) async {
      await _disposeScreen(tester);
      final invitation = _invitation();
      await tester.pumpWidget(
        _app(
          home: const ShareSendScreen(),
          overrides: _senderState(
            SenderShareState(
              phase: SharePhase.waiting,
              invitation: invitation,
              fileCount: 1,
              totalBytes: 4096,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.textContaining('Expires in'), findsOneWidget);
      expect(find.textContaining('Single use'), findsOneWidget);
      expect(find.text(invitation.token), findsNothing);
      expect(find.textContaining('192.168.'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders the approval, progress and result states', (
      tester,
    ) async {
      await _disposeScreen(tester);

      Future<void> pumpState(SenderShareState state) async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.pumpWidget(
          _app(home: const ShareSendScreen(), overrides: _senderState(state)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      }

      await pumpState(
        SenderShareState(
          phase: SharePhase.awaitingApproval,
          peerName: 'Receiver phone',
          path: SharePath.direct,
          fileCount: 1,
          totalBytes: 4096,
        ),
      );
      expect(find.text('Waiting for Receiver phone'), findsOneWidget);
      expect(find.text('Review in progress'), findsOneWidget);

      await pumpState(
        SenderShareState(
          phase: SharePhase.transferring,
          peerName: 'Receiver phone',
          path: SharePath.relayed,
          progress: const ShareProgress(
            transferredBytes: 512,
            totalBytes: 1024,
            fileCount: 1,
          ),
        ),
      );
      expect(find.text('Transferring to Receiver phone'), findsOneWidget);
      expect(find.text('Relayed connection'), findsWidgets);

      await pumpState(
        const SenderShareState(
          phase: SharePhase.completed,
          results: [
            ShareFileResult(
              fileName: 'field-notes.pdf',
              status: ShareResultStatus.imported,
            ),
          ],
          message: 'Delivered to Receiver phone.',
        ),
      );
      expect(find.text('Transfer finished'), findsOneWidget);
      expect(find.text('field-notes.pdf'), findsOneWidget);
    });
  });

  group('ShareReceiveScreen', () {
    testWidgets('landing asks for the camera and explains the flow', (
      tester,
    ) async {
      await _disposeScreen(tester);
      await tester.pumpWidget(
        _app(
          home: const ShareReceiveScreen(),
          overrides: [
            ..._receiverState(const ReceiverShareState.idle()),
            shareCrossNetworkConfiguredProvider.overrideWithValue(false),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Scan the sender’s code'), findsOneWidget);
      expect(find.text('Open camera'), findsOneWidget);
      expect(find.text('You see the files first'), findsOneWidget);
      expect(find.text('Nearby networks'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('approval lists every offered file and a total', (
      tester,
    ) async {
      await _disposeScreen(tester);
      await tester.pumpWidget(
        _app(
          home: const ShareReceiveScreen(),
          overrides: _receiverState(
            ReceiverShareState(
              phase: SharePhase.awaitingApproval,
              senderName: 'Sender phone',
              offer: _offer(),
              path: SharePath.localWifi,
              message: 'Review the files before receiving anything.',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('2 files from Sender phone'), findsOneWidget);
      expect(find.text('field-notes.pdf'), findsOneWidget);
      expect(find.text('second-book.epub'), findsOneWidget);
      expect(find.text('Approve & receive'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
      expect(find.text('Nothing saved yet'), findsOneWidget);
      expect(find.text('Local Wi-Fi'), findsOneWidget);
    });

    testWidgets('completed and failed results are explicit', (tester) async {
      await _disposeScreen(tester);

      await tester.pumpWidget(
        _app(
          home: const ShareReceiveScreen(),
          overrides: _receiverState(
            const ReceiverShareState(
              phase: SharePhase.completed,
              results: [
                ShareFileResult(
                  fileName: 'field-notes.pdf',
                  status: ShareResultStatus.imported,
                ),
              ],
              message: 'Received 1 file. It’s in your library.',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Files received'), findsOneWidget);
      expect(find.text('Open library'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      await tester.pumpWidget(
        _app(
          home: const ShareReceiveScreen(),
          overrides: _receiverState(
            const ReceiverShareState(
              phase: SharePhase.failed,
              message: 'The connection closed before the transfer finished.',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Transfer did not finish'), findsOneWidget);
      expect(find.text('Scan another code'), findsOneWidget);
    });
  });

  group('ShareScannerScreen', () {
    testWidgets('delivers one valid invitation and ignores duplicates', (
      tester,
    ) async {
      final invitation = _invitation();
      final received = <ShareInvitation>[];
      await _disposeScreen(tester);

      await tester.pumpWidget(
        _app(
          home: ShareScannerScreen(
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
      expect(find.text('Scan sender’s code'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('rejects a URL and can scan again', (tester) async {
      await _disposeScreen(tester);
      await tester.pumpWidget(
        _app(
          home: ShareScannerScreen(
            onInvitation: (_) => fail('A URL must never be accepted.'),
            scannerBuilder: (context, onDetect) => Center(
              child: FilledButton(
                onPressed: () => onDetect('https://example.com/relay'),
                child: const Text('Simulate bad scan'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Simulate bad scan'));
      await tester.pump();

      expect(find.text('Code not accepted'), findsOneWidget);
      expect(find.textContaining('isn’t a Relay share code'), findsOneWidget);

      await tester.tap(find.text('Scan again'));
      await tester.pump();
      expect(find.text('Code not accepted'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
