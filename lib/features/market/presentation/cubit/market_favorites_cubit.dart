import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/fc_squads/domain/repositories/player_card_catalog_repository.dart';
import 'package:fifa_queue/features/market/domain/repositories/market_favorites_repository.dart';
import 'package:fifa_queue/features/market/presentation/cubit/market_favorites_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Watchlist da aba Favoritos. `market_favorites` so guarda o id da carta --
/// a ficha completa (imagem, rating, posicao) vem do mesmo catalogo que a
/// busca do Mercado usa, nunca duplicada aqui.
class MarketFavoritesCubit extends Cubit<MarketFavoritesState> {
  MarketFavoritesCubit(this._favoritesRepository, this._catalogRepository)
    : super(const MarketFavoritesState());

  final MarketFavoritesRepository _favoritesRepository;
  final PlayerCardCatalogRepository _catalogRepository;

  Future<void> load() async {
    emit(
      state.copyWith(status: MarketFavoritesStatus.loading, clearFailure: true),
    );
    try {
      final ids = await _favoritesRepository.listFavoriteCardIds();
      if (ids.isEmpty) {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: MarketFavoritesStatus.empty,
              cards: const <PlayerCard>[],
            ),
          );
        }
        return;
      }
      final cards = await Future.wait(
        ids.map(_catalogRepository.getCard),
      );
      if (isClosed) {
        return;
      }
      final resolved = <PlayerCard>[for (final card in cards) ?card];
      emit(
        state.copyWith(
          status: resolved.isEmpty
              ? MarketFavoritesStatus.empty
              : MarketFavoritesStatus.ready,
          cards: resolved,
        ),
      );
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(
          state.copyWith(status: MarketFavoritesStatus.failure, failure: failure),
        );
      }
    }
  }

  Future<void> removeFavorite(String cardId) async {
    final previous = state.cards;
    final updated = previous.where((card) => card.id != cardId).toList();
    emit(
      state.copyWith(
        cards: updated,
        status: updated.isEmpty
            ? MarketFavoritesStatus.empty
            : MarketFavoritesStatus.ready,
      ),
    );
    try {
      await _favoritesRepository.removeFavorite(cardId);
    } on AppFailure {
      if (!isClosed) {
        emit(
          state.copyWith(cards: previous, status: MarketFavoritesStatus.ready),
        );
      }
    }
  }
}
