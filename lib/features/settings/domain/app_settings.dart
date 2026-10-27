import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

enum AppThemePreference { system, light, dark }

extension AppThemePreferenceX on AppThemePreference {
  ThemeMode get themeMode => switch (this) {
    AppThemePreference.system => ThemeMode.system,
    AppThemePreference.light => ThemeMode.light,
    AppThemePreference.dark => ThemeMode.dark,
  };

  String get label => switch (this) {
    AppThemePreference.system => 'System',
    AppThemePreference.light => 'Light',
    AppThemePreference.dark => 'Dark',
  };
}

enum LibraryViewMode { grid, list }

extension LibraryViewModeX on LibraryViewMode {
  String get label => this == LibraryViewMode.grid ? 'Grid' : 'List';
}

enum ReaderTheme { paper, night }

extension ReaderThemeX on ReaderTheme {
  String get label => this == ReaderTheme.paper ? 'Paper' : 'Night';
}

@freezed
abstract class AppSettings with _$AppSettings {
  const AppSettings._();

  const factory AppSettings({
    @Default(AppThemePreference.system) AppThemePreference theme,
    @Default(LibraryViewMode.grid) LibraryViewMode libraryView,
    @Default(ReaderTheme.paper) ReaderTheme readerTheme,
    @Default(1.0) double readerTextScale,
    @Default(false) bool reduceMotion,
    @Default(true) bool confirmBeforeCancel,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, Object?> json) =>
      _$AppSettingsFromJson(json);

  int get readerTextStep {
    const steps = [0.85, 1.0, 1.15, 1.3, 1.45];
    var closest = 0;
    for (var i = 0; i < steps.length; i++) {
      if ((steps[i] - readerTextScale).abs() <
          (steps[closest] - readerTextScale).abs()) {
        closest = i;
      }
    }
    return closest;
  }
}
