import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class MarketFavoritesRemoteDataSource {
  String? get currentUserId;

  Future<List<Map<String, dynamic>>> listFavorites(String userId);

  Future<void> addFavorite({required String userId, required String cardId});

  Future<void> removeFavorite({required String userId, required String cardId});
}

class SupabaseMarketFavoritesRemoteDataSource
    implements MarketFavoritesRemoteDataSource {
  const SupabaseMarketFavoritesRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<List<Map<String, dynamic>>> listFavorites(String userId) async {
    final rows = await _client
        .from('market_favorites')
        .select('card_id, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<void> addFavorite({required String userId, required String cardId}) =>
      _client.from('market_favorites')
      // ignoreDuplicates vira ON CONFLICT DO NOTHING -- sem isso, o upsert
      // gera ON CONFLICT DO UPDATE, que exige grant de UPDATE na tabela
      // (nao concedido, e nao faz sentido conceder: a linha nao tem coluna
      // mutavel alem de created_at, que nunca deve ser tocada de novo).
      // Sem o grant, todo addFavorite falhava com 42501 permission denied,
      // revertido em silencio pelo optimistic update do cubit.
      .upsert(<String, dynamic>{
        'user_id': userId,
        'card_id': cardId,
      }, ignoreDuplicates: true);

  @override
  Future<void> removeFavorite({
    required String userId,
    required String cardId,
  }) => _client
      .from('market_favorites')
      .delete()
      .eq('user_id', userId)
      .eq('card_id', cardId);
}
