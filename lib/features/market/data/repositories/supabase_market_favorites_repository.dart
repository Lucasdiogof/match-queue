import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/market/data/datasources/market_favorites_remote_data_source.dart';
import 'package:fifa_queue/features/market/domain/repositories/market_favorites_repository.dart';

class SupabaseMarketFavoritesRepository implements MarketFavoritesRepository {
  const SupabaseMarketFavoritesRepository(this._dataSource, this._errorMapper);

  final MarketFavoritesRemoteDataSource _dataSource;
  final SupabaseErrorMapper _errorMapper;

  @override
  Future<List<String>> listFavoriteCardIds() => _guard(() async {
    final rows = await _dataSource.listFavorites(_requireUserId());
    return <String>[for (final row in rows) '${row['card_id']}'];
  });

  @override
  Future<bool> isFavorite(String cardId) => _guard(() async {
    final ids = await _dataSource.listFavorites(_requireUserId());
    return ids.any((row) => row['card_id'] == cardId);
  });

  @override
  Future<void> addFavorite(String cardId) => _guard(
    () => _dataSource.addFavorite(userId: _requireUserId(), cardId: cardId),
  );

  @override
  Future<void> removeFavorite(String cardId) => _guard(
    () => _dataSource.removeFavorite(userId: _requireUserId(), cardId: cardId),
  );

  String _requireUserId() {
    final userId = _dataSource.currentUserId;
    if (userId == null || userId.isEmpty) {
      throw const AuthFailure(reason: AuthFailureReason.sessionExpired);
    }
    return userId;
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error) {
      throw _errorMapper.map(error);
    }
  }
}
