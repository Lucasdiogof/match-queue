import 'package:flutter/widgets.dart';

class AppLocales {
  const AppLocales._();

  static const Locale portuguese = Locale('pt', 'BR');
  static const Locale english = Locale('en');
  static const Locale spanish = Locale('es');

  static const Locale fallback = english;

  static const List<Locale> supported = <Locale>[portuguese, english, spanish];

  static bool isSupported(Locale locale) => supported.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  static Locale resolve(
    Locale? deviceLocale,
    Iterable<Locale> supportedLocales,
  ) {
    if (deviceLocale == null) {
      return fallback;
    }
    for (final locale in supportedLocales) {
      if (locale.languageCode == deviceLocale.languageCode &&
          locale.countryCode == deviceLocale.countryCode) {
        return locale;
      }
    }
    for (final locale in supportedLocales) {
      if (locale.languageCode == deviceLocale.languageCode) {
        return locale;
      }
    }
    return fallback;
  }

  static Locale? fromTag(String? tag) {
    if (tag == null || tag.isEmpty) {
      return null;
    }
    for (final locale in supported) {
      if (locale.toLanguageTag() == tag) {
        return locale;
      }
    }
    return null;
  }
}
