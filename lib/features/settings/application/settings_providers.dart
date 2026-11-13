import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../data/local_repositories.dart';
import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  ref.keepAlive();
  return PrefsSettingsRepository(ref.watch(sharedPreferencesProvider));
});

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    return ref.watch(settingsRepositoryProvider).read();
  }

  void setTheme(AppThemePreference preference) {
    _update(state.copyWith(theme: preference));
  }

  void setLibraryView(LibraryViewMode mode) {
    _update(state.copyWith(libraryView: mode));
  }

  void setReaderTheme(ReaderTheme theme) {
    _update(state.copyWith(readerTheme: theme));
  }

  void setReaderTextScale(double scale) {
    _update(state.copyWith(readerTextScale: scale.clamp(0.85, 1.45)));
  }

  void setReduceMotion(bool value) {
    _update(state.copyWith(reduceMotion: value));
  }

  void setConfirmBeforeCancel(bool value) {
    _update(state.copyWith(confirmBeforeCancel: value));
  }

  void resetReadingPreferences() {
    _update(
      state.copyWith(readerTheme: ReaderTheme.paper, readerTextScale: 1.0),
    );
  }

  void _update(AppSettings next) {
    state = next;
    unawaited(_persist(next));
  }

  Future<void> _persist(AppSettings settings) async {
    try {
      await ref.read(settingsRepositoryProvider).write(settings);
    } catch (error) {
      // Settings are a convenience, not user data. A failed preference write
      // must not surface as an unhandled asynchronous error or block the UI.
      assert(() {
        debugPrint('Relay could not save settings: $error');
        return true;
      }());
    }
  }
}
