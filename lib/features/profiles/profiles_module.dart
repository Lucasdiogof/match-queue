import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/profiles/data/datasources/profile_remote_data_source.dart';
import 'package:fifa_queue/features/profiles/data/repositories/supabase_profile_repository.dart';
import 'package:fifa_queue/features/profiles/data/selected_profile_store.dart';
import 'package:fifa_queue/features/profiles/domain/repositories/profile_repository.dart';
import 'package:fifa_queue/features/profiles/presentation/cubit/profiles_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void registerProfilesModule(
  GetIt sl, {
  required SupabaseClient supabaseClient,
}) {
  sl
    ..registerLazySingleton<SelectedProfileStore>(
      () => SelectedProfileStore(sl<SharedPreferences>()),
    )
    ..registerLazySingleton<ProfileRemoteDataSource>(
      () => SupabaseProfileRemoteDataSource(supabaseClient),
    )
    ..registerLazySingleton<ProfileRepository>(
      () => SupabaseProfileRepository(
        sl<ProfileRemoteDataSource>(),
        sl<SupabaseErrorMapper>(),
      ),
    );

  sl.registerLazySingleton<ProfilesCubit>(
    () => ProfilesCubit(sl<ProfileRepository>(), sl<SelectedProfileStore>()),
  );
}
