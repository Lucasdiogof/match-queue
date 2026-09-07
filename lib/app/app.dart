import 'package:fifa_queue/core/config/app_config.dart';
import 'package:fifa_queue/core/config/app_config_scope.dart';
import 'package:fifa_queue/core/design_system/theme/app_theme.dart';
import 'package:fifa_queue/core/l10n/app_locales.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/invitations/presentation/cubit/pending_invite_cubit.dart';
import 'package:fifa_queue/features/invitations/presentation/widgets/pending_invite_listener.dart';
import 'package:fifa_queue/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:fifa_queue/features/profile/presentation/widgets/profile_session_listener.dart';
import 'package:fifa_queue/features/settings/presentation/cubit/locale_cubit.dart';
import 'package:fifa_queue/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:fifa_queue/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class FifaQueueApp extends StatelessWidget {
  const FifaQueueApp({
    required this.config,
    required this.router,
    required this.authCubit,
    required this.themeCubit,
    required this.localeCubit,
    required this.pendingInviteCubit,
    required this.profileCubit,
    super.key,
  });

  final AppConfig config;
  final GoRouter router;
  final AuthCubit authCubit;
  final ThemeCubit themeCubit;
  final LocaleCubit localeCubit;
  final PendingInviteCubit pendingInviteCubit;
  final ProfileCubit profileCubit;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider<AuthCubit>.value(value: authCubit),
      BlocProvider<ThemeCubit>.value(value: themeCubit),
      BlocProvider<LocaleCubit>.value(value: localeCubit),
      BlocProvider<PendingInviteCubit>.value(value: pendingInviteCubit),
      BlocProvider<ProfileCubit>.value(value: profileCubit),
    ],
    child: AppConfigScope(
      config: config,
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) => BlocBuilder<LocaleCubit, Locale?>(
          builder: (context, locale) => MaterialApp.router(
            title: 'FIFA Queue',
            debugShowCheckedModeBanner: false,
            routerConfig: router,
            themeMode: themeMode,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            locale: locale,
            supportedLocales: AppLocales.supported,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            localeResolutionCallback: (deviceLocale, supportedLocales) =>
                AppLocales.resolve(locale ?? deviceLocale, supportedLocales),
            builder: (context, child) => ProfileSessionListener(
              child: PendingInviteListener(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
