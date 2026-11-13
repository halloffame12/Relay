import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/relay_buttons.dart';
import '../core/widgets/relay_states.dart';
import '../features/import/presentation/import_screen.dart';
import '../features/library/presentation/document_detail_screen.dart';
import '../features/library/presentation/library_screen.dart';
import '../features/reader/presentation/reader_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/share/presentation/share_home_screen.dart';
import '../features/share/presentation/share_receive_screen.dart';
import '../features/share/presentation/share_scanner_screen.dart';
import '../features/share/presentation/share_send_screen.dart';
import '../features/transfers/presentation/transfers_screen.dart';
import 'navigation/relay_shell.dart';
import 'theme/app_colors.dart';

final relayRouterProvider = Provider<GoRouter>((ref) {
  final router = createRelayRouter();
  ref.onDispose(router.dispose);
  return router;
});

GoRouter createRelayRouter() {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final libraryNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'library');
  final nearbyNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'nearby');
  final transfersNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'transfers',
  );
  final settingsNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'settings',
  );

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/library',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            RelayShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: libraryNavigatorKey,
            routes: [
              GoRoute(
                path: '/library',
                builder: (context, state) => const LibraryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: nearbyNavigatorKey,
            routes: [
              GoRoute(
                path: '/nearby',
                builder: (context, state) => const ShareHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: transfersNavigatorKey,
            routes: [
              GoRoute(
                path: '/transfers',
                builder: (context, state) => const TransfersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: settingsNavigatorKey,
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/document/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            DocumentDetailScreen(documentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/reader/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            ReaderScreen(documentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/import',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ImportScreen(),
      ),
      GoRoute(
        path: '/nearby/scan',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ShareScannerScreen(),
      ),
      GoRoute(
        path: '/nearby/send',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ShareSendScreen(),
      ),
      GoRoute(
        path: '/nearby/receive',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ShareReceiveScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        _RouteErrorPage(location: state.uri.toString()),
  );
}

class _RouteErrorPage extends StatelessWidget {
  const _RouteErrorPage({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    return Scaffold(
      backgroundColor: colors.canvas,
      body: SafeArea(
        child: RelayEmptyState(
          icon: Icons.explore_off_outlined,
          title: 'This page is not part of Relay',
          message: 'No screen is available for $location.',
          action: RelayButton(
            label: 'Back to library',
            icon: Icons.menu_book_rounded,
            onPressed: () => context.go('/library'),
          ),
        ),
      ),
    );
  }
}
