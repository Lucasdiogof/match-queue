import 'package:fifa_queue/core/config/app_config.dart';
import 'package:fifa_queue/core/logging/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseInitializer {
  const SupabaseInitializer(this._logger);

  final AppLogger _logger;

  /// Só é chamado depois que `AppConfig.isUsable` já garantiu
  /// `hasSupabase` -- sem config válida o bootstrap nem chega aqui, mostra
  /// `StartupFailureApp` antes.
  Future<SupabaseClient> initialize(AppConfig config) async {
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabasePublishableKey,
      debug: config.environment.isDevelopment && config.verboseLogging,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    _logger.info('Supabase inicializado para ${config.environment.key}.');
    return Supabase.instance.client;
  }
}
