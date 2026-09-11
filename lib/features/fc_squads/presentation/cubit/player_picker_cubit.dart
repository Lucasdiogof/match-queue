import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/fc_squads/domain/repositories/player_card_catalog_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum PlayerPickerStatus { loading, ready, failure }

class PlayerPickerState extends Equatable {
  const PlayerPickerState({
    this.status = PlayerPickerStatus.loading,
    this.cards = const <PlayerCard>[],
    this.query = '',
    this.hasMore = false,
    this.isLoadingMore = false,
    this.minRating,
    this.leagueName,
    this.clubName,
    this.nationName,
    this.compatibleOnly = false,
    this.failure,
  });

  final PlayerPickerStatus status;
  final List<PlayerCard> cards;
  final String query;
  final bool hasMore;
  final bool isLoadingMore;
  final int? minRating;
  final String? leagueName;
  final String? clubName;
  final String? nationName;

  /// Quando `true`, a busca é filtrada no servidor para só cartas elegíveis
  /// no slot -- fora de posição nunca fica escondido por padrão (item 43),
  /// isto é um filtro OPCIONAL que o usuário liga.
  final bool compatibleOnly;
  final AppFailure? failure;

  bool get hasActiveFilters =>
      minRating != null ||
      leagueName != null ||
      clubName != null ||
      nationName != null ||
      compatibleOnly;

  PlayerPickerState copyWith({
    PlayerPickerStatus? status,
    List<PlayerCard>? cards,
    String? query,
    bool? hasMore,
    bool? isLoadingMore,
    int? minRating,
    bool clearMinRating = false,
    String? leagueName,
    bool clearLeagueName = false,
    String? clubName,
    bool clearClubName = false,
    String? nationName,
    bool clearNationName = false,
    bool? compatibleOnly,
    AppFailure? failure,
    bool clearFailure = false,
  }) => PlayerPickerState(
    status: status ?? this.status,
    cards: cards ?? this.cards,
    query: query ?? this.query,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    minRating: clearMinRating ? null : (minRating ?? this.minRating),
    leagueName: clearLeagueName ? null : (leagueName ?? this.leagueName),
    clubName: clearClubName ? null : (clubName ?? this.clubName),
    nationName: clearNationName ? null : (nationName ?? this.nationName),
    compatibleOnly: compatibleOnly ?? this.compatibleOnly,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    cards,
    query,
    hasMore,
    isLoadingMore,
    minRating,
    leagueName,
    clubName,
    nationName,
    compatibleOnly,
    failure,
  ];
}

/// Busca do catálogo para um slot.
///
/// [positionCode] nulo = banco, onde qualquer carta serve. Com posição, a
/// busca já vem filtrada por elegibilidade (item 43), então o usuário não
/// consegue escolher alguém que a RPC recusaria depois.
class PlayerPickerCubit extends Cubit<PlayerPickerState> {
  PlayerPickerCubit(
    this._repository, {
    this.positionCode,
    this.excludeCardIds = const <String>[],
  }) : super(const PlayerPickerState());

  static const Duration searchDebounce = Duration(milliseconds: 300);
  static const int pageSize = 30;

  final PlayerCardCatalogRepository _repository;
  final String? positionCode;

  /// Cartas já ocupando outro slot do squad atual -- nunca oferecidas de
  /// novo aqui (gameplay flows refresh, item 4).
  final List<String> excludeCardIds;

  Timer? _debounce;
  int _generation = 0;

  Future<void> load() => _search(state.query);

  void search(String query) {
    emit(state.copyWith(query: query));
    _debounce?.cancel();
    _debounce = Timer(searchDebounce, () {
      if (!isClosed) {
        unawaited(_search(query));
      }
    });
  }

  void setMinRating(int? minRating) {
    emit(
      minRating == null
          ? state.copyWith(clearMinRating: true)
          : state.copyWith(minRating: minRating),
    );
    unawaited(_search(state.query));
  }

  void setLeagueName(String? leagueName) {
    emit(
      leagueName == null
          ? state.copyWith(clearLeagueName: true, clearClubName: true)
          : state.copyWith(leagueName: leagueName, clearClubName: true),
    );
    unawaited(_search(state.query));
  }

  void setClubName(String? clubName) {
    emit(
      clubName == null
          ? state.copyWith(clearClubName: true)
          : state.copyWith(clubName: clubName),
    );
    unawaited(_search(state.query));
  }

  void setNationName(String? nationName) {
    emit(
      nationName == null
          ? state.copyWith(clearNationName: true)
          : state.copyWith(nationName: nationName),
    );
    unawaited(_search(state.query));
  }

  void clearFilters() {
    emit(
      state.copyWith(
        clearMinRating: true,
        clearLeagueName: true,
        clearClubName: true,
        clearNationName: true,
        compatibleOnly: false,
      ),
    );
    unawaited(_search(state.query));
  }

  /// Filtro "Compatíveis": liga a mesma restrição de posição que a RPC já
  /// aplicava antes (`_fc_card_can_play`), agora OPCIONAL -- sem ele, o
  /// picker mostra TODO o catálogo, só ordenado por elegibilidade (item 43:
  /// nunca esconder fora de posição por padrão).
  void setCompatibleOnly(bool value) {
    if (positionCode == null) {
      return;
    }
    emit(state.copyWith(compatibleOnly: value));
    unawaited(_search(state.query));
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || isClosed) {
      return;
    }
    final generation = ++_generation;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final page = await _repository.searchCards(
        PlayerCardQuery(
          query: state.query.isEmpty ? null : state.query,
          position: state.compatibleOnly ? positionCode : null,
          limit: pageSize,
          offset: state.cards.length,
          minRating: state.minRating,
          leagueName: state.leagueName,
          clubName: state.clubName,
          nationName: state.nationName,
          excludeCardIds: excludeCardIds,
        ),
      );
      if (isClosed || generation != _generation) {
        return;
      }
      emit(
        state.copyWith(
          cards: _sortByEligibility(<PlayerCard>[
            ...state.cards,
            ...page.items,
          ]),
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } on AppFailure {
      if (!isClosed) {
        emit(state.copyWith(isLoadingMore: false));
      }
    }
  }

  Future<void> _search(String query) async {
    final generation = ++_generation;
    emit(
      state.copyWith(status: PlayerPickerStatus.loading, clearFailure: true),
    );
    try {
      final page = await _repository.searchCards(
        PlayerCardQuery(
          query: query.isEmpty ? null : query,
          position: state.compatibleOnly ? positionCode : null,
          limit: pageSize,
          minRating: state.minRating,
          leagueName: state.leagueName,
          clubName: state.clubName,
          nationName: state.nationName,
          excludeCardIds: excludeCardIds,
        ),
      );
      if (isClosed || generation != _generation) {
        return;
      }
      emit(
        state.copyWith(
          status: PlayerPickerStatus.ready,
          cards: _sortByEligibility(page.items),
          hasMore: page.hasMore,
          clearFailure: true,
        ),
      );
    } on AppFailure catch (failure) {
      if (!isClosed && generation == _generation) {
        emit(
          state.copyWith(status: PlayerPickerStatus.failure, failure: failure),
        );
      }
    }
  }

  /// Filtra e ordena por elegibilidade: posicao primaria primeiro, depois
  /// alternativa real. Quem nao joga ali FICA DE FORA.
  ///
  /// Antes so reordenava, entao um ST aparecia como sugestao de LB, apenas no
  /// fim da lista -- e a busca por texto atravessava a lista inteira. Sugerir
  /// jogador que nao atua na posicao nao e uma sugestao pior, e uma sugestao
  /// errada.
  ///
  /// A regra continua sendo a de [eligibilityTier]: posicao principal mais as
  /// alternativas declaradas na carta. Nada de equivalencia inventada do tipo
  /// "LB aceita qualquer defensor".
  ///
  /// `List.sort` nao e estavel em Dart, mas o desempate por rating ja vem do
  /// servidor (`order by rating desc`) dentro de cada pagina, entao o pior
  /// caso e reordenacao cosmetica dentro do mesmo rating.
  List<PlayerCard> _sortByEligibility(List<PlayerCard> cards) {
    final code = positionCode;
    if (code == null) {
      return cards;
    }
    return List<PlayerCard>.of(
      cards.where((card) => eligibilityTier(card, code) < 2),
    )..sort(
      (a, b) =>
          eligibilityTier(a, code).compareTo(eligibilityTier(b, code)),
    );
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}

/// 0 = posição primária, 1 = alternativa, 2 = fora de posição.
int eligibilityTier(PlayerCard card, String positionCode) {
  if (card.primaryPosition == positionCode) {
    return 0;
  }
  if (card.alternativePositions.contains(positionCode)) {
    return 1;
  }
  return 2;
}
