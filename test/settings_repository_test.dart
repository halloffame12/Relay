import 'package:flutter_test/flutter_test.dart';
import 'package:relay/features/settings/data/local_repositories.dart';
import 'package:relay/features/settings/domain/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('settings repository reads defaults and persists changes', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = PrefsSettingsRepository(preferences);

    final defaults = repository.read();
    expect(defaults.theme, AppThemePreference.system);
    expect(defaults.libraryView, LibraryViewMode.grid);
    expect(defaults.readerTheme, ReaderTheme.paper);
    expect(defaults.readerTextScale, 1.0);
    expect(defaults.reduceMotion, isFalse);
    expect(defaults.confirmBeforeCancel, isTrue);

    final updated = defaults.copyWith(
      theme: AppThemePreference.dark,
      libraryView: LibraryViewMode.list,
      readerTextScale: 1.3,
      reduceMotion: true,
    );
    await repository.write(updated);

    final readBack = repository.read();
    expect(readBack.theme, AppThemePreference.dark);
    expect(readBack.libraryView, LibraryViewMode.list);
    expect(readBack.readerTextScale, 1.3);
    expect(readBack.reduceMotion, isTrue);
  });

  test('unreadable settings fall back to defaults', () async {
    SharedPreferences.setMockInitialValues({'relay.settings.v1': 'not-json'});
    final preferences = await SharedPreferences.getInstance();
    final repository = PrefsSettingsRepository(preferences);

    final settings = repository.read();
    expect(settings.theme, AppThemePreference.system);
    expect(settings.libraryView, LibraryViewMode.grid);
  });

  test('reader text step snaps to the closest supported step', () {
    const settings = AppSettings(readerTextScale: 1.29);
    expect(settings.readerTextStep, 3);
    const smaller = AppSettings(readerTextScale: 0.9);
    expect(smaller.readerTextStep, 0);
  });
}
