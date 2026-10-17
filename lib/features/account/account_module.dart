import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/account/data/account_cache_store.dart';
import 'package:fifa_queue/features/account/data/datasources/account_remote_data_source.dart';
import 'package:fifa_queue/features/account/data/repositories/supabase_account_repository.dart';
import 'package:fifa_queue/features/account/domain/repositories/account_repository.dart';
import 'package:fifa_queue/features/account/presentation/cubit/account_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void registerAccountModule(GetIt sl, {required SupabaseClient supabaseClient}) {
  sl
    ..registerLazySingleton<AccountRemoteDataSource>(
      () => SupabaseAccountRemoteDataSource(supabaseClient),
    )
    ..registerLazySingleton<AccountRepository>(
      () => SupabaseAccountRepository(
        sl<AccountRemoteDataSource>(),
        sl<SupabaseErrorMapper>(),
      ),
    );

  sl
    ..registerLazySingleton<AccountCacheStore>(
      () => AccountCacheStore(sl<SharedPreferences>()),
    )
    ..registerLazySingleton<AccountCubit>(
      () => AccountCubit(
        sl<AccountRepository>(),
        cacheStore: sl<AccountCacheStore>(),
      ),
    );
}
