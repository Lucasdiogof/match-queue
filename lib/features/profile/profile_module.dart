import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/auth/domain/repositories/auth_repository.dart';
import 'package:fifa_queue/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:fifa_queue/features/profile/data/repositories/local_profile_repository.dart';
import 'package:fifa_queue/features/profile/data/repositories/supabase_profile_repository.dart';
import 'package:fifa_queue/features/profile/domain/repositories/profile_repository.dart';
import 'package:fifa_queue/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void registerProfileModule(
  GetIt sl, {
  required SupabaseClient? supabaseClient,
}) {
  if (supabaseClient == null) {
    sl.registerLazySingleton<ProfileRepository>(
      () => LocalProfileRepository(sl<AuthRepository>()),
    );
  } else {
    sl
      ..registerLazySingleton<ProfileRemoteDataSource>(
        () => SupabaseProfileRemoteDataSource(supabaseClient),
      )
      ..registerLazySingleton<ProfileRepository>(
        () => SupabaseProfileRepository(
          sl<ProfileRemoteDataSource>(),
          sl<SupabaseErrorMapper>(),
        ),
      );
  }

  sl.registerLazySingleton<ProfileCubit>(
    () => ProfileCubit(sl<ProfileRepository>()),
  );
}
