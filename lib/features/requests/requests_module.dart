import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/requests/data/datasources/requests_remote_data_source.dart';
import 'package:fifa_queue/features/requests/data/repositories/supabase_requests_repository.dart';
import 'package:fifa_queue/features/requests/domain/repositories/requests_repository.dart';
import 'package:fifa_queue/features/requests/presentation/cubit/requests_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void registerRequestsModule(
  GetIt sl, {
  required SupabaseClient supabaseClient,
}) {
  sl
    ..registerLazySingleton<RequestsRemoteDataSource>(
      () => SupabaseRequestsRemoteDataSource(supabaseClient),
    )
    ..registerLazySingleton<RequestsRepository>(
      () => SupabaseRequestsRepository(
        sl<RequestsRemoteDataSource>(),
        sl<SupabaseErrorMapper>(),
      ),
    )
    // Singleton: alimenta tanto a tela Solicitacoes quanto o badge da
    // bottom nav, que precisa do total pendente mesmo fora da tela.
    ..registerLazySingleton<RequestsCubit>(
      () => RequestsCubit(sl<RequestsRepository>()),
    );
}
