import 'dart:async';

import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/logging/app_logger.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/matchmaking_realtime_event.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/my_matchmaking_status.dart';
import 'package:fifa_queue/features/matchmaking/domain/repositories/matchmaking_repository.dart';
import 'package:fifa_queue/features/matchmaking/presentation/cubit/matchmaking_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Estado de matchmaking de uma CONTA (Etapa 11) -- escopado por instancia a
/// um fcAccountId (recriado pela tela Jogar quando a conta selecionada
/// muda), igual ao antigo escopo por time. Uma conta pode estar vinculada a
/// varios times: o realtime assina a revisao de CADA time vinculado e
/// qualquer um deles disparando invalidacao provoca uma releitura do read
/// model da conta inteira -- nunca um patch local.
class MatchmakingCubit extends Cubit<MatchmakingState> {
  MatchmakingCubit(this._repository, this._logger, {required this.fcAccountId})
    : super(const MatchmakingState());

  static const Duration invalidationDebounce = Duration(milliseconds: 200);

  final MatchmakingRepository _repository;
  final AppLogger _logger;
  final String fcAccountId;

  final List<StreamSubscription<MatchmakingRealtimeEvent>> _events =
      <StreamSubscription<MatchmakingRealtimeEvent>>[];
  List<String> _watchedTeamIds = <String>[];
  Timer? _debounce;
  int _loadGeneration = 0;

  Future<void> start() => load();

  Future<void> load() async {
    final generation = ++_loadGeneration;
    emit(state.copyWith(status: MatchmakingStatus.loading, clearFailure: true));
    try {
      final snapshot = await _repository.getMyStatus(fcAccountId);
      if (_isStale(generation)) {
        return;
      }
      _emitSnapshot(snapshot, status: MatchmakingStatus.ready);
      _resubscribeIfNeeded(snapshot.linkedTeamIds);
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
      final snapshot = await _repository.getMyStatus(fcAccountId);
      if (_isStale(generation)) {
        return;
      }
      _emitSnapshot(
        snapshot,
        status: MatchmakingStatus.ready,
        isRefreshing: false,
      );
      _resubscribeIfNeeded(snapshot.linkedTeamIds);
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
      fcSquadId: fcSquadId,
      mode: mode,
    ),
  );

  Future<bool> cancel() =>
      _runAction(() => _repository.cancelSearch(fcAccountId));

  Future<bool> matchFound() =>
      _runAction(() => _repository.reportMatchFound(fcAccountId));

  /// Reabre a assinatura Realtime so quando o conjunto de times vinculados
  /// muda de verdade (raro) -- nunca a cada snapshot, senao um refresh
  /// silencioso ficaria cancelando e reabrindo canal sem necessidade.
  void _resubscribeIfNeeded(List<String> teamIds) {
    if (_sameIds(_watchedTeamIds, teamIds)) {
      return;
    }
    _watchedTeamIds = List<String>.from(teamIds);
    for (final sub in _events) {
      unawaited(sub.cancel());
    }
    _events.clear();
    for (final teamId in _watchedTeamIds) {
      _events.add(
        _repository
            .watchTeam(teamId)
            .listen(_onRealtimeEvent, onError: _onRealtimeError),
      );
    }
  }

  bool _sameIds(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    final setA = a.toSet();
    return setA.length == b.toSet().length && setA.containsAll(b);
  }

  void _onRealtimeEvent(MatchmakingRealtimeEvent event) {
    if (isClosed) {
      return;
    }
    switch (event) {
      case MatchmakingSubscribed():
        final wasDisconnected =
            state.connection == MatchmakingConnection.disconnected;
        _logger.info('realtime subscribed (fc account $fcAccountId)');
        emit(state.copyWith(connection: MatchmakingConnection.connected));
        if (wasDisconnected) {
          unawaited(refreshSilently());
        }
      case MatchmakingRealtimeLost():
        _logger.info('realtime disconnected (fc account $fcAccountId)');
        emit(state.copyWith(connection: MatchmakingConnection.disconnected));
      case MatchmakingStateInvalidated(:final revision):
        _logger.debug(
          'matchmaking state invalidated (fc account $fcAccountId, revision '
          '${revision ?? '-'})',
        );
        _scheduleRefresh();
    }
  }

  void _onRealtimeError(Object error, StackTrace stackTrace) {
    _logger.warning(
      'realtime channel error (fc account $fcAccountId)',
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
        _resubscribeIfNeeded(snapshot.linkedTeamIds);
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
        clearFailure: true,
      ),
    );
  }

  @override
  Future<void> close() async {
    _debounce?.cancel();
    _debounce = null;
    for (final sub in _events) {
      await sub.cancel();
    }
    _events.clear();
    return super.close();
  }
}
