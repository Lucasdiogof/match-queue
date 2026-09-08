import 'package:fifa_queue/core/config/app_config.dart';
import 'package:fifa_queue/core/di/core_module.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/firebase/firebase_bootstrap.dart';
import 'package:fifa_queue/core/logging/app_logger.dart';
import 'package:fifa_queue/features/auth/auth_module.dart';
import 'package:fifa_queue/features/game/game_module.dart';
import 'package:fifa_queue/features/history/history_module.dart';
import 'package:fifa_queue/features/invitations/invitations_module.dart';
import 'package:fifa_queue/features/matchmaking/matchmaking_module.dart';
import 'package:fifa_queue/features/notifications/notifications_module.dart';
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
  required FirebaseAvailability firebaseAvailability,
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
  registerMatchmakingModule(getIt, supabaseClient: supabaseClient);
  registerGameModule(getIt, supabaseClient: supabaseClient);
  registerHistoryModule(getIt, supabaseClient: supabaseClient);
  registerNotificationsModule(
    getIt,
    supabaseClient: supabaseClient,
    firebaseAvailability: firebaseAvailability,
  );

  await getIt.allReady();
}
