import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/application/settings_providers.dart';
import '../features/settings/domain/app_settings.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class RelayApp extends ConsumerWidget {
  const RelayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      title: 'Relay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.theme.themeMode,
      routerConfig: ref.watch(relayRouterProvider),
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        if (!settings.reduceMotion) return child;
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(disableAnimations: true),
          child: child,
        );
      },
    );
  }
}
