import 'package:material_ui/material_ui.dart' show ThemeMode;
import 'package:flutter/widgets.dart' show Locale;

abstract interface class SettingsRepository {
  ThemeMode readThemeMode();

  Future<void> writeThemeMode(ThemeMode mode);

  Locale? readLocale();

  Future<void> writeLocale(Locale? locale);
}
