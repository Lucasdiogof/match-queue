import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/auth/domain/repositories/auth_repository.dart';
import 'package:fifa_queue/features/fc_accounts/data/datasources/fc_account_remote_data_source.dart';
import 'package:fifa_queue/features/fc_accounts/data/repositories/local_fc_account_repository.dart';
import 'package:fifa_queue/features/fc_accounts/data/repositories/supabase_fc_account_repository.dart';
import 'package:fifa_queue/features/fc_accounts/data/selected_fc_account_store.dart';
import 'package:fifa_queue/features/fc_accounts/domain/repositories/fc_account_repository.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void registerFcAccountsModule(
  GetIt sl, {
  required SupabaseClient? supabaseClient,
}) {
  sl.registerLazySingleton<SelectedFcAccountStore>(
    () => SelectedFcAccountStore(sl<SharedPreferences>()),
  );

  if (supabaseClient == null) {
    sl.registerLazySingleton<FcAccountRepository>(
      () => LocalFcAccountRepository(
        sl<AuthRepository>(),
        sl<SharedPreferences>(),
      ),
    );
  } else {
    sl
      ..registerLazySingleton<FcAccountRemoteDataSource>(
        () => SupabaseFcAccountRemoteDataSource(supabaseClient),
      )
      ..registerLazySingleton<FcAccountRepository>(
        () => SupabaseFcAccountRepository(
          sl<FcAccountRemoteDataSource>(),
          sl<SupabaseErrorMapper>(),
        ),
      );
  }

  sl.registerLazySingleton<FcAccountsCubit>(
    () => FcAccountsCubit(
      sl<FcAccountRepository>(),
      sl<SelectedFcAccountStore>(),
    ),
  );
}
