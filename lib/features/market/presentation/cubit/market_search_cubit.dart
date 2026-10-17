import 'dart:async';

import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/fc_squads/domain/repositories/player_card_catalog_repository.dart';
import 'package:fifa_queue/features/market/domain/repositories/market_favorites_repository.dart';
import 'package:fifa_queue/features/market/presentation/cubit/market_search_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Busca da aba Mercado.
///
/// Nunca carrega nada sozinho: [search] so consulta o catalogo quando o
/// termo (aparado) tem pelo menos [minQueryLength] caracteres -- termo mais
/// curto volta pro estado inicial em vez de disparar request. Debounce de
/// 300ms, mesmo valor ja usado no picker de carta do Squad Builder
/// (PlayerPickerCubit) -- convencao da casa, nao um numero novo.
class MarketSearchCubit extends Cubit<MarketSearchState> {
  MarketSearchCubit(this._catalogRepository, this._favoritesRepository)
    : super(const MarketSearchState());

  static const Duration searchDebounce = Duration(milliseconds: 300);
  static const int minQueryLength = 2;
  static const int pageLimit = 30;

  final PlayerCardCatalogRepository _catalogRepository;
  final MarketFavoritesRepository _favoritesRepository;

  Timer? _debounce;
  int _generation = 0;
  PlayerCardQuery? _lastQuery;

  Future<void> loadFavoriteIds() async {
    try {
      final ids = await _favoritesRepository.listFavoriteCardIds();
      if (!isClosed) {
        emit(state.copyWith(favoriteCardIds: ids.toSet()));
      }
    } on AppFailure {
      // Falha silenciosa aqui de proposito: o pior caso e o icone de
      // favorito comecar "nao favoritado" ate a proxima sincronizacao --
      // nunca bloqueia a busca em si, que e a funcao principal da tela.
    }
  }

  void search(String query) {
    emit(state.copyWith(query: query));
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.length < minQueryLength) {
      final generation = ++_generation;
      if (generation == _generation) {
        emit(
          state.copyWith(
            status: MarketSearchStatus.initial,
            cards: const <PlayerCard>[],
            hasMore: false,
            isLoadingMore: false,
            clearFailure: true,
          ),
        );
      }
      return;
    }
    _debounce = Timer(searchDebounce, () {
      if (!isClosed) {
        unawaited(_search(trimmed));
      }
    });
  }

  Future<void> _search(String query) async {
    final generation = ++_generation;
    emit(
      state.copyWith(status: MarketSearchStatus.loading, clearFailure: true),
    );
    try {
      final request = PlayerCardQuery(query: query, limit: pageLimit);
      final page = await _catalogRepository.searchCards(request);
      if (isClosed || generation != _generation) {
        return;
      }
      _lastQuery = request;
      emit(
        state.copyWith(
          status: page.items.isEmpty
              ? MarketSearchStatus.noResults
              : MarketSearchStatus.ready,
          cards: page.items,
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } on AppFailure catch (failure) {
      if (!isClosed && generation == _generation) {
        emit(
          state.copyWith(status: MarketSearchStatus.failure, failure: failure),
        );
      }
    }
  }

  /// Proxima pagina da busca atual. Uma pessoa pode ter varias cartas
  /// (versao base, TOTW, eventos...): a identidade de uma carta e o id dela,
  /// nunca o nome, entao so descartamos ids que ja estao na lista.
  Future<void> loadMore() async {
    final lastQuery = _lastQuery;
    if (lastQuery == null ||
        !state.hasMore ||
        state.isLoadingMore ||
        state.status != MarketSearchStatus.ready) {
      return;
    }
    final generation = _generation;
    emit(state.copyWith(isLoadingMore: true, clearFailure: true));
    final nextQuery = lastQuery.nextPage();
    try {
      final page = await _catalogRepository.searchCards(nextQuery);
      if (isClosed || generation != _generation) {
        return;
      }
      _lastQuery = nextQuery;
      final knownIds = state.cards.map((card) => card.id).toSet();
      emit(
        state.copyWith(
          cards: <PlayerCard>[
            ...state.cards,
            for (final card in page.items)
              if (!knownIds.contains(card.id)) card,
          ],
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } on AppFailure catch (failure) {
      if (!isClosed && generation == _generation) {
        // Mantem a lista ja carregada; o botao "Carregar mais" continua e
        // serve de nova tentativa.
        emit(state.copyWith(isLoadingMore: false, failure: failure));
      }
    }
  }

  Future<void> toggleFavorite(String cardId) async {
    final wasFavorite = state.favoriteCardIds.contains(cardId);
    final optimistic = Set<String>.of(state.favoriteCardIds);
    // Otimista: a lista de favoritos de verdade e so consultada de novo
    // quando a aba Favoritos abre -- aqui so o icone deste resultado precisa
    // refletir a acao na hora.
    if (wasFavorite) {
      optimistic.remove(cardId);
    } else {
      optimistic.add(cardId);
    }
    emit(state.copyWith(favoriteCardIds: optimistic));
    try {
      if (wasFavorite) {
        await _favoritesRepository.removeFavorite(cardId);
      } else {
        await _favoritesRepository.addFavorite(cardId);
      }
    } on AppFailure {
      if (!isClosed) {
        // Reverte pro estado anterior a tentativa.
        final reverted = Set<String>.of(optimistic);
        if (wasFavorite) {
          reverted.add(cardId);
        } else {
          reverted.remove(cardId);
        }
        emit(state.copyWith(favoriteCardIds: reverted));
      }
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
