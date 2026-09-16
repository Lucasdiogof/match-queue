/// Watchlist pessoal de cartas (feature Mercado). So a relacao
/// usuario<->carta -- ver comentario da migration `market_favorites` para o
/// porque disso nunca significar compra/venda.
abstract interface class MarketFavoritesRepository {
  /// Ids das cartas favoritadas pelo usuario logado, mais recentes primeiro.
  Future<List<String>> listFavoriteCardIds();

  Future<bool> isFavorite(String cardId);

  Future<void> addFavorite(String cardId);

  Future<void> removeFavorite(String cardId);
}
