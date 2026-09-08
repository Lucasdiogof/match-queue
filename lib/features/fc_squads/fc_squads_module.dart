import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/fc_squads/data/datasources/fc_squad_remote_data_source.dart';
import 'package:fifa_queue/features/fc_squads/data/repositories/local_fc_squad_repository.dart';
import 'package:fifa_queue/features/fc_squads/data/repositories/supabase_fc_squad_repository.dart';
import 'package:fifa_queue/features/fc_squads/data/repositories/supabase_player_card_catalog_repository.dart';
import 'package:fifa_queue/features/fc_squads/domain/repositories/fc_squad_repository.dart';
import 'package:fifa_queue/features/fc_squads/domain/repositories/player_card_catalog_repository.dart';
import 'package:fifa_queue/features/fc_squads/presentation/cubit/fc_squads_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void registerFcSquadsModule(
  GetIt sl, {
  required SupabaseClient? supabaseClient,
}) {
  if (supabaseClient == null) {
    sl
      ..registerLazySingleton<PlayerCardCatalogRepository>(
        LocalPlayerCardCatalogRepository.new,
      )
      ..registerLazySingleton<FcSquadRepository>(
        () => LocalFcSquadRepository(
          sl<SharedPreferences>(),
          sl<PlayerCardCatalogRepository>(),
        ),
      )
      ..registerLazySingleton<FcSquadsCubit>(
        () => FcSquadsCubit(sl<FcSquadRepository>()),
      );
    return;
  }

  sl
    ..registerLazySingleton<FcSquadRemoteDataSource>(
      () => SupabaseFcSquadRemoteDataSource(supabaseClient),
    )
    ..registerLazySingleton<PlayerCardCatalogRepository>(
      () => SupabasePlayerCardCatalogRepository(
        supabaseClient,
        sl<SupabaseErrorMapper>(),
      ),
    )
    ..registerLazySingleton<FcSquadRepository>(
      () => SupabaseFcSquadRepository(
        sl<FcSquadRemoteDataSource>(),
        sl<SupabaseErrorMapper>(),
      ),
    );

  sl.registerLazySingleton<FcSquadsCubit>(
    () => FcSquadsCubit(sl<FcSquadRepository>()),
  );
}
