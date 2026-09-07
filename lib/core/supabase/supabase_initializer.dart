import 'package:fifa_queue/core/config/app_config.dart';
import 'package:fifa_queue/core/logging/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseInitializer {
  const SupabaseInitializer(this._logger);

  final AppLogger _logger;

  Future<SupabaseClient?> initialize(AppConfig config) async {
    if (!config.hasSupabase) {
      _logger.warning(
        'Supabase não configurado (${config.missingRequiredKeys.join(', ')}). '
        'O app segue em modo local de desenvolvimento.',
      );
      return null;
    }

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
