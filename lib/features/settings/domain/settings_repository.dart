import '../domain/app_settings.dart';

abstract interface class SettingsRepository {
  AppSettings read();

  Future<void> write(AppSettings settings);
}
