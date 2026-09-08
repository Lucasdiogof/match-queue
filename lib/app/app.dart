import 'package:fifa_queue/core/config/app_config.dart';
import 'package:fifa_queue/core/config/app_config_scope.dart';
import 'package:fifa_queue/core/design_system/theme/app_theme.dart';
import 'package:fifa_queue/core/l10n/app_locales.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/fc_accounts_session_listener.dart';
import 'package:fifa_queue/features/fc_squads/presentation/cubit/fc_squads_cubit.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/fc_squads_session_listener.dart';
import 'package:fifa_queue/features/game/presentation/cubit/pending_match_cubit.dart';
import 'package:fifa_queue/features/game/presentation/widgets/pending_match_session_listener.dart';
import 'package:fifa_queue/features/invitations/presentation/cubit/pending_invite_cubit.dart';
import 'package:fifa_queue/features/invitations/presentation/widgets/pending_invite_listener.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/features/matchmaking/presentation/cubit/game_mode_cubit.dart';
import 'package:fifa_queue/features/notifications/presentation/widgets/notification_lifecycle_listener.dart';
import 'package:fifa_queue/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:fifa_queue/features/profile/presentation/widgets/locale_sync_listener.dart';
import 'package:fifa_queue/features/profile/presentation/widgets/presence_heartbeat_listener.dart';
import 'package:fifa_queue/features/profile/presentation/widgets/profile_session_listener.dart';
import 'package:fifa_queue/features/settings/presentation/cubit/locale_cubit.dart';
import 'package:fifa_queue/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/teams_session_listener.dart';
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
    required this.teamsCubit,
    required this.pendingMatchCubit,
    required this.fcAccountsCubit,
    super.key,
  });

  final AppConfig config;
  final GoRouter router;
  final AuthCubit authCubit;
  final ThemeCubit themeCubit;
  final LocaleCubit localeCubit;
  final PendingInviteCubit pendingInviteCubit;
  final ProfileCubit profileCubit;
  final TeamsCubit teamsCubit;
  final PendingMatchCubit pendingMatchCubit;
  final FcAccountsCubit fcAccountsCubit;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider<AuthCubit>.value(value: authCubit),
      BlocProvider<ThemeCubit>.value(value: themeCubit),
      BlocProvider<LocaleCubit>.value(value: localeCubit),
      BlocProvider<PendingInviteCubit>.value(value: pendingInviteCubit),
      BlocProvider<ProfileCubit>.value(value: profileCubit),
      BlocProvider<TeamsCubit>.value(value: teamsCubit),
      BlocProvider<PendingMatchCubit>.value(value: pendingMatchCubit),
      BlocProvider<FcAccountsCubit>.value(value: fcAccountsCubit),
      BlocProvider<FcSquadsCubit>(create: (_) => getIt<FcSquadsCubit>()),
      BlocProvider<GameModeCubit>(create: (_) => getIt<GameModeCubit>()),
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
              child: TeamsSessionListener(
                child: FcAccountsSessionListener(
                  child: FcSquadsSessionListener(
                    child: PendingMatchSessionListener(
                      child: LocaleSyncListener(
                        child: PresenceHeartbeatListener(
                          child: NotificationLifecycleListener(
                            child: PendingInviteListener(
                              child: child ?? const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
