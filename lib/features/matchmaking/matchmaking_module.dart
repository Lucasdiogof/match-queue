import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/auth/domain/repositories/auth_repository.dart';
import 'package:fifa_queue/features/matchmaking/data/datasources/matchmaking_remote_data_source.dart';
import 'package:fifa_queue/features/matchmaking/data/repositories/local_matchmaking_repository.dart';
import 'package:fifa_queue/features/matchmaking/data/repositories/supabase_matchmaking_repository.dart';
import 'package:fifa_queue/features/matchmaking/data/selected_game_mode_store.dart';
import 'package:fifa_queue/features/matchmaking/domain/repositories/matchmaking_repository.dart';
import 'package:fifa_queue/features/matchmaking/presentation/cubit/game_mode_cubit.dart';
import 'package:fifa_queue/features/teams/domain/repositories/team_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void registerMatchmakingModule(
  GetIt sl, {
  required SupabaseClient? supabaseClient,
}) {
  sl
    ..registerLazySingleton<SelectedGameModeStore>(
      () => SelectedGameModeStore(sl<SharedPreferences>()),
    )
    ..registerLazySingleton<GameModeCubit>(
      () => GameModeCubit(sl<SelectedGameModeStore>()),
    );

  if (supabaseClient == null) {
    sl.registerLazySingleton<MatchmakingRepository>(
      () => LocalMatchmakingRepository(
        sl<AuthRepository>(),
        sl<TeamRepository>(),
        sl<SharedPreferences>(),
      ),
    );
    return;
  }

  sl
    ..registerLazySingleton<MatchmakingRemoteDataSource>(
      () => SupabaseMatchmakingRemoteDataSource(supabaseClient),
    )
    ..registerLazySingleton<MatchmakingRepository>(
      () => SupabaseMatchmakingRepository(
        sl<MatchmakingRemoteDataSource>(),
        sl<SupabaseErrorMapper>(),
      ),
    );
}
