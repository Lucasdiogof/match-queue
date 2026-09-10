import 'dart:async';

import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/logging/app_logger.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/matchmaking_realtime_event.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/my_matchmaking_status.dart';
import 'package:fifa_queue/features/matchmaking/domain/repositories/matchmaking_repository.dart';
import 'package:fifa_queue/features/matchmaking/presentation/cubit/matchmaking_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Estado de matchmaking de uma CONTA num TIME especifico -- fila real por
/// time (evolucao da Etapa 11): cada Time tem sua propria fila e seu proprio
/// estado, entao o cubit e recriado quando a conta OU o time selecionado
/// mudam. So existe UM canal Realtime (o do time desta tela), nunca mais um
/// por time vinculado -- a fila de outro time so importa se um dia a UI
/// mostrar as duas ao mesmo tempo.
class MatchmakingCubit extends Cubit<MatchmakingState> {
  MatchmakingCubit(
    this._repository,
    this._logger, {
    required this.fcAccountId,
    required this.teamId,
  }) : super(const MatchmakingState());

  static const Duration invalidationDebounce = Duration(milliseconds: 200);

  final MatchmakingRepository _repository;
  final AppLogger _logger;
  final String fcAccountId;
  final String teamId;

  StreamSubscription<MatchmakingRealtimeEvent>? _subscription;
  Timer? _debounce;
  int _loadGeneration = 0;

  Future<void> start() {
    _subscribe();
    return load();
  }

  Future<void> load() async {
    final generation = ++_loadGeneration;
    emit(state.copyWith(status: MatchmakingStatus.loading, clearFailure: true));
    try {
      final snapshot = await _repository.getMyStatus(
        fcAccountId: fcAccountId,
        teamId: teamId,
      );
      if (_isStale(generation)) {
        return;
      }
      _emitSnapshot(snapshot, status: MatchmakingStatus.ready);
    } on AppFailure catch (failure) {
      if (_isStale(generation)) {
        return;
      }
      emit(state.copyWith(status: MatchmakingStatus.failure, failure: failure));
    }
  }

  /// Usado por invalidacao do Realtime, refresh de seguranca, retorno de
  /// foreground e fim do timer.
  Future<void> refreshSilently() async {
    final generation = ++_loadGeneration;
    emit(state.copyWith(isRefreshing: true));
    try {
      final snapshot = await _repository.getMyStatus(
        fcAccountId: fcAccountId,
        teamId: teamId,
      );
      if (_isStale(generation)) {
        return;
      }
      _emitSnapshot(
        snapshot,
        status: MatchmakingStatus.ready,
        isRefreshing: false,
      );
    } on AppFailure {
      if (_isStale(generation)) {
        return;
      }
      emit(state.copyWith(isRefreshing: false));
    }
  }

  Future<bool> startSearch(GameMode mode, {String? fcSquadId}) => _runAction(
    () => _repository.requestSearch(
      fcAccountId: fcAccountId,
      teamId: teamId,
      fcSquadId: fcSquadId,
      mode: mode,
    ),
  );

  Future<bool> cancel() =>
      _runAction(() => _repository.cancelSearch(fcAccountId));

  Future<bool> leaveQueue() => _runAction(
    () => _repository.leaveQueue(fcAccountId: fcAccountId, teamId: teamId),
  );

  Future<bool> matchFound() =>
      _runAction(() => _repository.reportMatchFound(fcAccountId));

  Future<bool> requestPriority() async {
    if (state.isActionPending) {
      return false;
    }
    emit(state.copyWith(isActionPending: true, clearFailure: true));
    try {
      await _repository.requestPriority(
        fcAccountId: fcAccountId,
        teamId: teamId,
      );
      if (!isClosed) {
        emit(state.copyWith(isActionPending: false, priorityRequestSent: true));
      }
      return true;
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(isActionPending: false, failure: failure));
      }
      return false;
    }
  }

  void _subscribe() {
    _subscription = _repository
        .watchTeam(teamId)
        .listen(_onRealtimeEvent, onError: _onRealtimeError);
  }

  void _onRealtimeEvent(MatchmakingRealtimeEvent event) {
    if (isClosed) {
      return;
    }
    switch (event) {
      case MatchmakingSubscribed():
        final wasDisconnected =
            state.connection == MatchmakingConnection.disconnected;
        _logger.info('realtime subscribed (team $teamId)');
        emit(state.copyWith(connection: MatchmakingConnection.connected));
        if (wasDisconnected) {
          unawaited(refreshSilently());
        }
      case MatchmakingRealtimeLost():
        _logger.info('realtime disconnected (team $teamId)');
        emit(state.copyWith(connection: MatchmakingConnection.disconnected));
      case MatchmakingStateInvalidated(:final revision):
        _logger.debug(
          'matchmaking state invalidated (team $teamId, revision '
          '${revision ?? '-'})',
        );
        _scheduleRefresh();
    }
  }

  void _onRealtimeError(Object error, StackTrace stackTrace) {
    _logger.warning(
      'realtime channel error (team $teamId)',
      error: error,
      stackTrace: stackTrace,
    );
    if (!isClosed) {
      emit(state.copyWith(connection: MatchmakingConnection.disconnected));
    }
  }

  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(invalidationDebounce, () {
      if (!isClosed) {
        unawaited(refreshSilently());
      }
    });
  }

  Future<bool> _runAction(
    Future<MyMatchmakingSnapshot> Function() action,
  ) async {
    if (state.isActionPending) {
      return false;
    }
    final generation = ++_loadGeneration;
    emit(state.copyWith(isActionPending: true, clearFailure: true));
    try {
      final snapshot = await action();
      if (isClosed) {
        return true;
      }
      if (generation == _loadGeneration) {
        _emitSnapshot(
          snapshot,
          status: MatchmakingStatus.ready,
          isActionPending: false,
        );
      } else {
        emit(state.copyWith(isActionPending: false));
      }
      return true;
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(isActionPending: false, failure: failure));
      }
      return false;
    }
  }

  bool _isStale(int generation) => isClosed || generation != _loadGeneration;

  void _emitSnapshot(
    MyMatchmakingSnapshot snapshot, {
    required MatchmakingStatus status,
    bool? isActionPending,
    bool? isRefreshing,
  }) {
    if (isClosed) {
      return;
    }
    final wasQueued = state.snapshot?.myStatus == MyMatchmakingStatus.queued;
    final isNowSearching = snapshot.myStatus == MyMatchmakingStatus.searching;
    final promoted = wasQueued && isNowSearching;
    final changedSearch =
        state.snapshot?.searching?.sessionId != snapshot.searching?.sessionId;

    emit(
      state.copyWith(
        status: status,
        snapshot: snapshot,
        isActionPending: isActionPending,
        isRefreshing: isRefreshing,
        serverOffset: snapshot.serverNow.difference(DateTime.now()),
        promotionNonce: promoted
            ? state.promotionNonce + 1
            : state.promotionNonce,
        // A confirmacao de "prioridade solicitada" so vale enquanto a MESMA
        // busca continua ativa -- uma busca nova (mesmo que a mesma conta)
        // pode receber outro pedido de prioridade.
        priorityRequestSent: changedSearch ? false : state.priorityRequestSent,
        clearFailure: true,
      ),
    );
  }

  @override
  Future<void> close() async {
    _debounce?.cancel();
    _debounce = null;
    await _subscription?.cancel();
    return super.close();
  }
}
