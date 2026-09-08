import 'dart:async';

import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/game/domain/entities/game_result.dart';
import 'package:fifa_queue/features/game/domain/repositories/game_repository.dart';
import 'package:fifa_queue/features/game/presentation/cubit/pending_match_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Partida pendente de resultado do usuário (no máximo uma, em qualquer
/// time) e a campanha de Weekend League atual. App-scoped como
/// ProfileCubit/TeamsCubit -- carregado no bootstrap quando há sessão
/// restaurada, nunca por time.
class PendingMatchCubit extends Cubit<PendingMatchState> {
  PendingMatchCubit(this._repository) : super(const PendingMatchState());

  final GameRepository _repository;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: PendingMatchStatus.loading,
        clearActionFailure: true,
      ),
    );
    try {
      final (match, event) = await (
        _repository.fetchPending(),
        _repository.fetchCurrentWeekendLeagueEvent(),
      ).wait;
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: PendingMatchStatus.ready,
          match: match,
          clearMatch: match == null,
          weekendLeagueEvent: event,
          clearWeekendLeagueEvent: event == null,
          clearActionFailure: true,
        ),
      );
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: PendingMatchStatus.failure,
            actionFailure: failure,
          ),
        );
      }
    }
  }

  /// Usado depois de "Encontrei" e no retorno de foreground: nunca propaga
  /// falha pra UI, o card só permanece no último estado bom conhecido.
  Future<void> refreshSilently() async {
    try {
      final (match, event) = await (
        _repository.fetchPending(),
        _repository.fetchCurrentWeekendLeagueEvent(),
      ).wait;
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: PendingMatchStatus.ready,
          match: match,
          clearMatch: match == null,
          weekendLeagueEvent: event,
          clearWeekendLeagueEvent: event == null,
          clearActionFailure: true,
        ),
      );
    } on AppFailure {
      // silencioso de proposito -- ver doc acima.
    }
  }

  Future<bool> finish({
    GameResult? result,
    int? goalsFor,
    int? goalsAgainst,
  }) async {
    final match = state.match;
    if (match == null || state.isSaving) {
      return false;
    }
    emit(state.copyWith(isSaving: true, clearActionFailure: true));
    try {
      await _repository.finishMatch(
        matchId: match.id,
        result: result,
        goalsFor: goalsFor,
        goalsAgainst: goalsAgainst,
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            status: PendingMatchStatus.ready,
            clearMatch: true,
            isSaving: false,
            clearActionFailure: true,
          ),
        );
      }
      return true;
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(isSaving: false, actionFailure: failure));
      }
      return false;
    }
  }

  void clear() => emit(const PendingMatchState());
}
