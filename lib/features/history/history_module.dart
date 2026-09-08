import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/history/data/datasources/history_remote_data_source.dart';
import 'package:fifa_queue/features/history/data/repositories/local_history_repository.dart';
import 'package:fifa_queue/features/history/data/repositories/supabase_history_repository.dart';
import 'package:fifa_queue/features/history/domain/repositories/history_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void registerHistoryModule(
  GetIt sl, {
  required SupabaseClient? supabaseClient,
}) {
  if (supabaseClient == null) {
    sl.registerLazySingleton<HistoryRepository>(LocalHistoryRepository.new);
    return;
  }

  sl
    ..registerLazySingleton<HistoryRemoteDataSource>(
      () => SupabaseHistoryRemoteDataSource(supabaseClient),
    )
    ..registerLazySingleton<HistoryRepository>(
      () => SupabaseHistoryRepository(
        sl<HistoryRemoteDataSource>(),
        sl<SupabaseErrorMapper>(),
      ),
    );
}
