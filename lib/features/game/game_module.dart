import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/game/data/datasources/game_remote_data_source.dart';
import 'package:fifa_queue/features/game/data/repositories/local_game_repository.dart';
import 'package:fifa_queue/features/game/data/repositories/supabase_game_repository.dart';
import 'package:fifa_queue/features/game/domain/repositories/game_repository.dart';
import 'package:fifa_queue/features/game/presentation/cubit/pending_match_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void registerGameModule(GetIt sl, {required SupabaseClient? supabaseClient}) {
  if (supabaseClient == null) {
    sl.registerLazySingleton<GameRepository>(() => const LocalGameRepository());
  } else {
    sl
      ..registerLazySingleton<GameRemoteDataSource>(
        () => SupabaseGameRemoteDataSource(supabaseClient),
      )
      ..registerLazySingleton<GameRepository>(
        () => SupabaseGameRepository(
          sl<GameRemoteDataSource>(),
          sl<SupabaseErrorMapper>(),
        ),
      );
  }

  sl.registerLazySingleton<PendingMatchCubit>(
    () => PendingMatchCubit(sl<GameRepository>()),
  );
}
