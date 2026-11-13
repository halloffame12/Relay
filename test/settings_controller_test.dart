import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay/features/settings/application/settings_providers.dart';
import 'package:relay/features/settings/domain/app_settings.dart';
import 'package:relay/features/settings/domain/settings_repository.dart';

void main() {
  test(
    'a failed preference write does not escape the settings controller',
    () async {
      final repository = _FailingSettingsRepository();
      final container = ProviderContainer(
        overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final controller = container.read(settingsProvider.notifier);
      controller.setTheme(AppThemePreference.dark);
      expect(container.read(settingsProvider).theme, AppThemePreference.dark);

      await Future<void>.delayed(Duration.zero);
      expect(repository.lastWrite?.theme, AppThemePreference.dark);
    },
  );
}

class _FailingSettingsRepository implements SettingsRepository {
  AppSettings? lastWrite;

  @override
  AppSettings read() => const AppSettings();

  @override
  Future<void> write(AppSettings settings) async {
    lastWrite = settings;
    throw StateError('Simulated preference write failure.');
  }
}
