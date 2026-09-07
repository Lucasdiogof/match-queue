import 'dart:async';

import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/logging/app_logger.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/matchmaking_realtime_event.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/matchmaking_snapshot.dart';
import 'package:fifa_queue/features/matchmaking/domain/repositories/matchmaking_repository.dart';
import 'package:fifa_queue/features/matchmaking/presentation/cubit/matchmaking_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Estado de matchmaking de um time. Escopado por instancia a um teamId
/// (recriado pela Home quando o time selecionado muda), igual ao
/// InviteManagementCubit -- nunca um singleton do app.
///
/// O Realtime aqui e apenas um sino: nenhum evento carrega estado e nenhum
/// evento e aplicado como patch local. Todo evento provoca uma releitura de
/// get_team_matchmaking_state, que continua sendo a unica fonte de verdade.
/// Isso e o que torna evento duplicado, fora de ordem ou atrasado
/// inofensivo -- no pior caso vira uma releitura redundante.
class MatchmakingCubit extends Cubit<MatchmakingState> {
  MatchmakingCubit(this._repository, this._logger, {required this.teamId})
    : super(const MatchmakingState());

  /// Uma transacao do servidor pode mexer em sessao, fila e promocao de
  /// uma vez so. Como todas viram uma unica revisao, na pratica chega um
  /// evento -- mas a janela curta tambem agrupa rajadas legitimas (varias
  /// pessoas agindo ao mesmo tempo) numa releitura so.
  static const Duration invalidationDebounce = Duration(milliseconds: 200);

  final MatchmakingRepository _repository;
  final AppLogger _logger;
  final String teamId;

  StreamSubscription<MatchmakingRealtimeEvent>? _events;
  Timer? _debounce;

  /// Toda leitura recebe um numero. Se a resposta chegar depois de outra
  /// leitura ter comecado, ela e descartada -- e o que impede a resposta
  /// lenta de um refresh antigo sobrescrever o resultado fresco de uma
  /// acao que o usuario acabou de fazer.
  int _loadGeneration = 0;

  Future<void> start() {
    _events ??= _repository
        .watchTeam(teamId)
        .listen(_onRealtimeEvent, onError: _onRealtimeError);
    return load();
  }

  Future<void> load() async {
    final generation = ++_loadGeneration;
    emit(state.copyWith(status: MatchmakingStatus.loading, clearFailure: true));
    try {
      final snapshot = await _repository.getState(teamId);
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
  /// foreground e fim do timer: nunca volta pro estado de loading (evitaria
  /// um flash de skeleton) e nunca propaga falha pra UI -- se a rede falhar
  /// por um instante o ultimo snapshot bom continua na tela.
  Future<void> refreshSilently() async {
    final generation = ++_loadGeneration;
    emit(state.copyWith(isRefreshing: true));
    try {
      final snapshot = await _repository.getState(teamId);
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

  Future<bool> startSearch() => _runAction(_repository.requestSearch);

  Future<bool> cancel() => _runAction(_repository.cancelSearch);

  Future<bool> matchFound() => _runAction(_repository.reportMatchFound);

  void _onRealtimeEvent(MatchmakingRealtimeEvent event) {
    if (isClosed) {
      return;
    }
    switch (event) {
      case MatchmakingSubscribed():
        // Voltar de uma queda significa que eventos podem ter passado
        // enquanto estivemos fora: reconcilia com o servidor em vez de
        // confiar no que ficou na tela.
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
    Future<MatchmakingSnapshot> Function(String teamId) action,
  ) async {
    if (state.isActionPending) {
      return false;
    }
    final generation = ++_loadGeneration;
    emit(state.copyWith(isActionPending: true, clearFailure: true));
    try {
      final snapshot = await action(teamId);
      if (isClosed) {
        return true;
      }
      // A resposta da acao e sempre um estado valido; so nao pode
      // sobrescrever uma leitura ainda mais recente que tenha comecado
      // depois dela.
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
    MatchmakingSnapshot snapshot, {
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
    await _events?.cancel();
    _events = null;
    return super.close();
  }
}
