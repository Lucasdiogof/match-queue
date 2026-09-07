import 'package:fifa_queue/core/config/app_config.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/logging/app_logger.dart';
import 'package:fifa_queue/core/observability/analytics_service.dart';
import 'package:fifa_queue/core/observability/crash_reporter.dart';
import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void registerCoreModule(
  GetIt sl, {
  required AppConfig config,
  required AppLogger logger,
  required SharedPreferences preferences,
  required SupabaseClient? supabaseClient,
}) {
  sl
    ..registerSingleton<AppConfig>(config)
    ..registerSingleton<AppLogger>(logger)
    ..registerSingleton<SharedPreferences>(preferences)
    ..registerSingleton<CrashReporter>(LoggingCrashReporter(logger))
    ..registerSingleton<AnalyticsService>(LoggingAnalyticsService(logger))
    ..registerSingleton<SupabaseErrorMapper>(const SupabaseErrorMapper())
    ..registerSingleton<SessionScope>(SessionScope(sl));

  if (supabaseClient != null) {
    sl.registerSingleton<SupabaseClient>(supabaseClient);
  }
}
