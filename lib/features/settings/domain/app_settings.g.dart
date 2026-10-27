// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => _AppSettings(
  theme:
      $enumDecodeNullable(_$AppThemePreferenceEnumMap, json['theme']) ??
      AppThemePreference.system,
  libraryView:
      $enumDecodeNullable(_$LibraryViewModeEnumMap, json['libraryView']) ??
      LibraryViewMode.grid,
  readerTheme:
      $enumDecodeNullable(_$ReaderThemeEnumMap, json['readerTheme']) ??
      ReaderTheme.paper,
  readerTextScale: (json['readerTextScale'] as num?)?.toDouble() ?? 1.0,
  reduceMotion: json['reduceMotion'] as bool? ?? false,
  confirmBeforeCancel: json['confirmBeforeCancel'] as bool? ?? true,
);

Map<String, dynamic> _$AppSettingsToJson(_AppSettings instance) =>
    <String, dynamic>{
      'theme': _$AppThemePreferenceEnumMap[instance.theme]!,
      'libraryView': _$LibraryViewModeEnumMap[instance.libraryView]!,
      'readerTheme': _$ReaderThemeEnumMap[instance.readerTheme]!,
      'readerTextScale': instance.readerTextScale,
      'reduceMotion': instance.reduceMotion,
      'confirmBeforeCancel': instance.confirmBeforeCancel,
    };

const _$AppThemePreferenceEnumMap = {
  AppThemePreference.system: 'system',
  AppThemePreference.light: 'light',
  AppThemePreference.dark: 'dark',
};

const _$LibraryViewModeEnumMap = {
  LibraryViewMode.grid: 'grid',
  LibraryViewMode.list: 'list',
};

const _$ReaderThemeEnumMap = {
  ReaderTheme.paper: 'paper',
  ReaderTheme.night: 'night',
};
