import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/market/data/datasources/market_favorites_remote_data_source.dart';
import 'package:fifa_queue/features/market/data/repositories/futnext_market_price_repository.dart';
import 'package:fifa_queue/features/market/data/repositories/supabase_market_favorites_repository.dart';
import 'package:fifa_queue/features/market/domain/repositories/market_favorites_repository.dart';
import 'package:fifa_queue/features/market/domain/repositories/market_price_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void registerMarketModule(GetIt sl, {required SupabaseClient supabaseClient}) {
  sl
    ..registerLazySingleton<MarketFavoritesRemoteDataSource>(
      () => SupabaseMarketFavoritesRemoteDataSource(supabaseClient),
    )
    ..registerLazySingleton<MarketFavoritesRepository>(
      () => SupabaseMarketFavoritesRepository(
        sl<MarketFavoritesRemoteDataSource>(),
        sl<SupabaseErrorMapper>(),
      ),
    )
    ..registerLazySingleton<MarketPriceRepository>(
      () => FutNextMarketPriceRepository(supabaseClient),
    );
}
