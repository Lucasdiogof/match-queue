import 'package:fifa_queue/core/config/app_config.dart';
import 'package:fifa_queue/core/di/core_module.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/logging/app_logger.dart';
import 'package:fifa_queue/features/auth/auth_module.dart';
import 'package:fifa_queue/features/invitations/invitations_module.dart';
import 'package:fifa_queue/features/profile/profile_module.dart';
import 'package:fifa_queue/features/settings/settings_module.dart';
import 'package:fifa_queue/features/teams/teams_module.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> registerDependencies({
  required AppConfig config,
  required AppLogger logger,
  required SharedPreferences preferences,
  required SupabaseClient? supabaseClient,
}) async {
  registerCoreModule(
    getIt,
    config: config,
    logger: logger,
    preferences: preferences,
    supabaseClient: supabaseClient,
  );
  registerSettingsModule(getIt);
  registerAuthModule(getIt, supabaseClient: supabaseClient);
  registerProfileModule(getIt, supabaseClient: supabaseClient);
  registerTeamsModule(getIt, supabaseClient: supabaseClient);
  registerInvitationsModule(getIt, supabaseClient: supabaseClient);

  await getIt.allReady();
}
