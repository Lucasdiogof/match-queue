import 'dart:async';

import 'package:fifa_queue/app/app.dart';
import 'package:fifa_queue/app/dependencies.dart';
import 'package:fifa_queue/app/router/app_router.dart';
import 'package:fifa_queue/app/startup_failure_app.dart';
import 'package:fifa_queue/core/config/app_config.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/firebase/firebase_bootstrap.dart';
import 'package:fifa_queue/core/logging/app_logger.dart';
import 'package:fifa_queue/core/navigation/url_strategy/url_strategy.dart';
import 'package:fifa_queue/core/observability/crash_reporter.dart';
import 'package:fifa_queue/core/supabase/supabase_initializer.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/invitations/presentation/cubit/pending_invite_cubit.dart';
import 'package:fifa_queue/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:fifa_queue/features/settings/presentation/cubit/locale_cubit.dart';
import 'package:fifa_queue/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> bootstrap() async {
  final config = AppConfig.fromEnvironment();
  final logger = _createLogger(config);
  final crashReporter = LoggingCrashReporter(logger);

  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      configureUrlStrategy();

      FlutterError.onError = (details) {
        unawaited(
          crashReporter.recordError(
            details.exception,
            details.stack,
            fatal: true,
          ),
        );
        FlutterError.presentError(details);
      };

      if (!config.isUsable) {
        logger.error(
          'Configuração obrigatória ausente: '
          '${config.missingRequiredKeys.join(', ')}',
        );
        runApp(StartupFailureApp(missingKeys: config.missingRequiredKeys));
        return;
      }

      final preferences = await SharedPreferences.getInstance();
      final supabaseClient = await SupabaseInitializer(
        logger,
      ).initialize(config);
      await FirebaseBootstrap(logger).initialize(config);

      await registerDependencies(
        config: config,
        logger: logger,
        preferences: preferences,
        supabaseClient: supabaseClient,
      );

      final authCubit = getIt<AuthCubit>()..initialize();
      final pendingInviteCubit = getIt<PendingInviteCubit>()..restore();
      final profileCubit = getIt<ProfileCubit>();
      final teamsCubit = getIt<TeamsCubit>();

      final restoredUser = authCubit.state.user;
      if (restoredUser != null) {
        unawaited(
          profileCubit.load(fallbackDisplayName: restoredUser.shortName),
        );
        unawaited(teamsCubit.load(userId: restoredUser.id));
      }

      logger.info('FIFA Queue iniciado em ${config.environment.key}.');

      runApp(
        FifaQueueApp(
          config: config,
          router: AppRouter(authCubit: authCubit).build(),
          authCubit: authCubit,
          themeCubit: getIt<ThemeCubit>(),
          localeCubit: getIt<LocaleCubit>(),
          pendingInviteCubit: pendingInviteCubit,
          profileCubit: profileCubit,
          teamsCubit: teamsCubit,
        ),
      );
    },
    (error, stackTrace) =>
        unawaited(crashReporter.recordError(error, stackTrace, fatal: true)),
  );
}

AppLogger _createLogger(AppConfig config) {
  if (config.environment.isProduction && !config.verboseLogging) {
    return const SilentAppLogger();
  }
  return const ConsoleAppLogger(
    minimumLevel: kReleaseMode ? LogLevel.warning : LogLevel.debug,
  );
}
