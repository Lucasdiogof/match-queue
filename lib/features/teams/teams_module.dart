import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/auth/domain/repositories/auth_repository.dart';
import 'package:fifa_queue/features/profile/domain/repositories/profile_repository.dart';
import 'package:fifa_queue/features/teams/data/datasources/team_remote_data_source.dart';
import 'package:fifa_queue/features/teams/data/repositories/local_team_repository.dart';
import 'package:fifa_queue/features/teams/data/repositories/supabase_team_repository.dart';
import 'package:fifa_queue/features/teams/data/selected_team_store.dart';
import 'package:fifa_queue/features/teams/domain/repositories/team_repository.dart';
import 'package:fifa_queue/features/teams/domain/usecases/create_team.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void registerTeamsModule(GetIt sl, {required SupabaseClient? supabaseClient}) {
  sl.registerLazySingleton<SelectedTeamStore>(
    () => SelectedTeamStore(sl<SharedPreferences>()),
  );

  if (supabaseClient == null) {
    sl.registerLazySingleton<TeamRepository>(
      () => LocalTeamRepository(
        sl<AuthRepository>(),
        sl<ProfileRepository>(),
        sl<SharedPreferences>(),
      ),
    );
  } else {
    sl
      ..registerLazySingleton<TeamRemoteDataSource>(
        () => SupabaseTeamRemoteDataSource(supabaseClient),
      )
      ..registerLazySingleton<TeamRepository>(
        () => SupabaseTeamRepository(
          sl<TeamRemoteDataSource>(),
          sl<SupabaseErrorMapper>(),
        ),
      );
  }

  sl
    ..registerLazySingleton<CreateTeam>(() => CreateTeam(sl<TeamRepository>()))
    ..registerLazySingleton<TeamsCubit>(
      () => TeamsCubit(
        sl<TeamRepository>(),
        sl<CreateTeam>(),
        sl<SelectedTeamStore>(),
      ),
    );
}
