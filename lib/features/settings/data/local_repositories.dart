import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';

class PrefsSettingsRepository implements SettingsRepository {
  PrefsSettingsRepository(this._preferences);

  static const _key = 'relay.settings.v1';

  final SharedPreferences _preferences;

  @override
  AppSettings read() {
    final raw = _preferences.getString(_key);
    if (raw == null) return const AppSettings();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AppSettings.fromJson(decoded);
      }
    } on FormatException {
      // Fall back to defaults if a stored value is unreadable.
    }
    return const AppSettings();
  }

  @override
  Future<void> write(AppSettings settings) async {
    await _preferences.setString(_key, jsonEncode(settings.toJson()));
  }
}
