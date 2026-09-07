import 'package:fifa_queue/core/l10n/app_locales.dart';
import 'package:fifa_queue/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart' show Locale;
import 'package:shared_preferences/shared_preferences.dart';

class LocalSettingsRepository implements SettingsRepository {
  const LocalSettingsRepository(this._preferences);

  static const String _themeModeKey = 'settings.theme_mode';
  static const String _localeKey = 'settings.locale';

  final SharedPreferences _preferences;

  @override
  ThemeMode readThemeMode() {
    final stored = _preferences.getString(_themeModeKey);
    return switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  @override
  Future<void> writeThemeMode(ThemeMode mode) =>
      _preferences.setString(_themeModeKey, mode.name);

  @override
  Locale? readLocale() =>
      AppLocales.fromTag(_preferences.getString(_localeKey));

  @override
  Future<void> writeLocale(Locale? locale) async {
    if (locale == null) {
      await _preferences.remove(_localeKey);
      return;
    }
    await _preferences.setString(_localeKey, locale.toLanguageTag());
  }
}
