import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:fifa_queue/features/auth/data/repositories/local_auth_repository.dart';
import 'package:fifa_queue/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:fifa_queue/features/auth/domain/repositories/auth_repository.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void registerAuthModule(GetIt sl, {required SupabaseClient? supabaseClient}) {
  if (supabaseClient == null) {
    sl.registerLazySingleton<AuthRepository>(LocalAuthRepository.new);
  } else {
    sl
      ..registerLazySingleton<AuthRemoteDataSource>(
        () => SupabaseAuthRemoteDataSource(supabaseClient),
      )
      ..registerLazySingleton<AuthRepository>(
        () => SupabaseAuthRepository(
          sl<AuthRemoteDataSource>(),
          sl<SupabaseErrorMapper>(),
        ),
      );
  }

  sl.registerLazySingleton<AuthCubit>(() => AuthCubit(sl<AuthRepository>()));
}
