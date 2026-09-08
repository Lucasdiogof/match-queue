import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/auth/domain/repositories/auth_repository.dart';
import 'package:fifa_queue/features/public_profile/data/datasources/public_profile_remote_data_source.dart';
import 'package:fifa_queue/features/public_profile/data/repositories/local_public_profile_repository.dart';
import 'package:fifa_queue/features/public_profile/data/repositories/supabase_public_profile_repository.dart';
import 'package:fifa_queue/features/public_profile/domain/repositories/public_profile_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void registerPublicProfileModule(
  GetIt sl, {
  required SupabaseClient? supabaseClient,
}) {
  if (supabaseClient == null) {
    sl.registerLazySingleton<PublicProfileRepository>(
      () => LocalPublicProfileRepository(
        sl<AuthRepository>(),
        sl<SharedPreferences>(),
      ),
    );
  } else {
    sl
      ..registerLazySingleton<PublicProfileRemoteDataSource>(
        () => SupabasePublicProfileRemoteDataSource(supabaseClient),
      )
      ..registerLazySingleton<PublicProfileRepository>(
        () => SupabasePublicProfileRepository(
          sl<PublicProfileRemoteDataSource>(),
          sl<SupabaseErrorMapper>(),
        ),
      );
  }
}
