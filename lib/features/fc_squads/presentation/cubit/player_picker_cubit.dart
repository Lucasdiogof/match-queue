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
    this.failure,
  });

  final PlayerPickerStatus status;
  final List<PlayerCard> cards;
  final String query;
  final bool hasMore;
  final bool isLoadingMore;
  final AppFailure? failure;

  PlayerPickerState copyWith({
    PlayerPickerStatus? status,
    List<PlayerCard>? cards,
    String? query,
    bool? hasMore,
    bool? isLoadingMore,
    AppFailure? failure,
    bool clearFailure = false,
  }) => PlayerPickerState(
    status: status ?? this.status,
    cards: cards ?? this.cards,
    query: query ?? this.query,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    cards,
    query,
    hasMore,
    isLoadingMore,
    failure,
  ];
}

/// Busca do catálogo para um slot.
///
/// [positionCode] nulo = banco, onde qualquer carta serve. Com posição, a
/// busca já vem filtrada por elegibilidade (item 43), então o usuário não
/// consegue escolher alguém que a RPC recusaria depois.
class PlayerPickerCubit extends Cubit<PlayerPickerState> {
  PlayerPickerCubit(this._repository, {this.positionCode})
    : super(const PlayerPickerState());

  static const Duration searchDebounce = Duration(milliseconds: 300);
  static const int pageSize = 30;

  final PlayerCardCatalogRepository _repository;
  final String? positionCode;

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
          position: positionCode,
          limit: pageSize,
          offset: state.cards.length,
        ),
      );
      if (isClosed || generation != _generation) {
        return;
      }
      emit(
        state.copyWith(
          cards: <PlayerCard>[...state.cards, ...page.items],
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
          position: positionCode,
          limit: pageSize,
        ),
      );
      if (isClosed || generation != _generation) {
        return;
      }
      emit(
        state.copyWith(
          status: PlayerPickerStatus.ready,
          cards: page.items,
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

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
