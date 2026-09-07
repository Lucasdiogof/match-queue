import 'package:fifa_queue/core/design_system/components/app_error_state.dart';
import 'package:fifa_queue/core/design_system/theme/app_theme.dart';
import 'package:fifa_queue/core/l10n/app_locales.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class StartupFailureApp extends StatelessWidget {
  const StartupFailureApp({required this.missingKeys, super.key});

  final List<String> missingKeys;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FIFA Queue',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    supportedLocales: AppLocales.supported,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    localeResolutionCallback: (deviceLocale, supportedLocales) =>
        AppLocales.resolve(deviceLocale, supportedLocales),
    home: Builder(
      builder: (context) => Scaffold(
        body: AppErrorState(
          title: context.l10n.startupErrorTitle,
          message: context.l10n.startupErrorMessage(missingKeys.join(', ')),
        ),
      ),
    ),
  );
}
