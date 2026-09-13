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
    this.leagueName,
    this.nationName,
    this.compatibleOnly = true,
    this.failure,
  });

  final PlayerPickerStatus status;
  final List<PlayerCard> cards;
  final String query;
  final bool hasMore;
  final bool isLoadingMore;
  final String? leagueName;
  final String? nationName;

  /// Ligado por padrão quando o picker abre por um slot: só quem joga
  /// naquela posição aparece navegando. O usuário pode desligar aqui, e
  /// digitar um nome na busca também libera (ver doc da classe).
  final bool compatibleOnly;
  final AppFailure? failure;

  bool get hasActiveFilters =>
      leagueName != null || nationName != null || !compatibleOnly;

  PlayerPickerState copyWith({
    PlayerPickerStatus? status,
    List<PlayerCard>? cards,
    String? query,
    bool? hasMore,
    bool? isLoadingMore,
    String? leagueName,
    bool clearLeagueName = false,
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
    leagueName: clearLeagueName ? null : (leagueName ?? this.leagueName),
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
    leagueName,
    nationName,
    compatibleOnly,
    failure,
  ];
}

/// Busca do catálogo para um slot.
///
/// [positionCode] nulo = banco, onde qualquer carta serve. Com posição, a
/// navegação (sem termo de busca, com "Compatíveis" ligado) só mostra quem
/// joga ali -- decisão explícita do dono do produto, substituindo o
/// comportamento anterior (item 43, "nunca esconder por padrão"). Digitar um
/// nome na busca sempre libera o filtro de posição, mesmo com "Compatíveis"
/// ligado: a intenção já é clara, o usuário quer aquela carta específica.
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

  void setLeagueName(String? leagueName) {
    emit(
      leagueName == null
          ? state.copyWith(clearLeagueName: true)
          : state.copyWith(leagueName: leagueName),
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

  void setCompatibleOnly(bool value) {
    if (positionCode == null) {
      return;
    }
    emit(state.copyWith(compatibleOnly: value));
    unawaited(_search(state.query));
  }

  void clearFilters() {
    emit(
      state.copyWith(
        clearLeagueName: true,
        clearNationName: true,
        compatibleOnly: true,
      ),
    );
    unawaited(_search(state.query));
  }

  /// Filtro de posição só entra navegando (sem termo de busca) com
  /// "Compatíveis" ligado -- ver doc da classe.
  String? _positionFilterFor(String query) =>
      state.compatibleOnly && query.trim().isEmpty ? positionCode : null;

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
          position: _positionFilterFor(state.query),
          limit: pageSize,
          offset: state.cards.length,
          leagueName: state.leagueName,
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
          position: _positionFilterFor(query),
          limit: pageSize,
          leagueName: state.leagueName,
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

  /// Sempre ORDENA por elegibilidade (posição primária, depois alternativa,
  /// depois fora de posição) -- nunca filtra aqui: quando a posição deveria
  /// restringir a lista, isso já aconteceu no servidor via
  /// [_positionFilterFor]. Filtrar de novo no cliente reintroduziria o bug
  /// de página vazia (ex.: GK nunca aparecia nos 30 cards de maior overall)
  /// que motivou o filtro ir para o servidor.
  List<PlayerCard> _sortByEligibility(List<PlayerCard> cards) {
    final code = positionCode;
    if (code == null) {
      return cards;
    }
    return List<PlayerCard>.of(cards)..sort(
      (a, b) => eligibilityTier(a, code).compareTo(eligibilityTier(b, code)),
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
