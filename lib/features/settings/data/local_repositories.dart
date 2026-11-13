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
        final settings = AppSettings.fromJson(decoded);
        final scale = settings.readerTextScale;
        return settings.copyWith(
          readerTextScale: scale.isFinite
              ? scale.clamp(0.85, 1.45).toDouble()
              : 1.0,
        );
      }
    } catch (_) {
      // Stored preferences are untrusted input. A truncated write, a removed
      // enum value or a field with the wrong type must never prevent startup.
    }
    return const AppSettings();
  }

  @override
  Future<void> write(AppSettings settings) async {
    await _preferences.setString(_key, jsonEncode(settings.toJson()));
  }
}
