import 'dart:async';

import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/game/domain/entities/game_result.dart';
import 'package:fifa_queue/features/game/domain/repositories/game_repository.dart';
import 'package:fifa_queue/features/game/presentation/cubit/pending_match_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Partidas do usuario pendentes de resultado, em qualquer time. App-scoped
/// como ProfileCubit/TeamsCubit -- carregado no bootstrap quando ha sessao
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
      final matches = await _repository.fetchPendingMatches();
      if (!isClosed) {
        emit(
          state.copyWith(
            status: PendingMatchStatus.ready,
            matches: matches,
            clearActionFailure: true,
          ),
        );
      }
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
  /// falha pra UI, a lista so permanece no ultimo estado bom conhecido.
  Future<void> refreshSilently() async {
    try {
      final matches = await _repository.fetchPendingMatches();
      if (!isClosed) {
        emit(
          state.copyWith(
            status: PendingMatchStatus.ready,
            matches: matches,
            clearActionFailure: true,
          ),
        );
      }
    } on AppFailure {
      // silencioso de proposito -- ver doc acima.
    }
  }

  /// Informa o resultado. Sem [matchId], age sobre a pendencia mais recente.
  Future<bool> finish({
    String? matchId,
    GameResult? result,
    int? goalsFor,
    int? goalsAgainst,
  }) => _mutate(
    matchId,
    (id) => _repository.finishMatch(
      matchId: id,
      result: result,
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
    ),
  );

  /// Descartar e um desfecho legitimo, nao um erro: a partida sai da lista
  /// sem virar vitoria nem derrota e nada disso bloqueia a proxima busca.
  Future<bool> discard({String? matchId}) =>
      _mutate(matchId, _repository.discardMatch);

  /// Dispensa tudo de uma vez, para quem nao quer registrar nada.
  Future<bool> dismissAll() async {
    if (state.isSaving || !state.hasPending) {
      return false;
    }
    emit(state.copyWith(isSaving: true, clearActionFailure: true));
    try {
      await _repository.dismissAllPendingMatches();
      await _reloadAfterMutation();
      return true;
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(isSaving: false, actionFailure: failure));
      }
      return false;
    }
  }

  Future<bool> _mutate(
    String? matchId,
    Future<void> Function(String id) action,
  ) async {
    final target = matchId ?? state.match?.id;
    if (target == null || state.isSaving) {
      return false;
    }
    emit(state.copyWith(isSaving: true, clearActionFailure: true));
    try {
      await action(target);
      await _reloadAfterMutation();
      return true;
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(isSaving: false, actionFailure: failure));
      }
      return false;
    }
  }

  /// Rele do servidor em vez de remover a linha localmente: com varias
  /// pendencias, adivinhar o novo conjunto no cliente e como as listas
  /// ficam dessincronizadas.
  Future<void> _reloadAfterMutation() async {
    try {
      final matches = await _repository.fetchPendingMatches();
      if (!isClosed) {
        emit(
          state.copyWith(
            status: PendingMatchStatus.ready,
            matches: matches,
            isSaving: false,
            clearActionFailure: true,
          ),
        );
      }
    } on AppFailure {
      if (!isClosed) {
        emit(state.copyWith(isSaving: false));
      }
    }
  }

  void clear() => emit(const PendingMatchState());
}
