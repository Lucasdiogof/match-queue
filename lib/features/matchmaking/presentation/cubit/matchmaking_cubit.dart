import 'dart:async';

import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/logging/app_logger.dart';
import 'package:fifa_queue/features/matchmaking/data/search_cooldown_store.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/matchmaking_realtime_event.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/my_matchmaking_status.dart';
import 'package:fifa_queue/features/matchmaking/domain/repositories/matchmaking_repository.dart';
import 'package:fifa_queue/features/matchmaking/presentation/cubit/matchmaking_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Estado de matchmaking de uma CONTA num TIME e MODO especificos --
/// Champions e Rivals sao filas independentes do mesmo Time (pedido
/// explicito: as duas nao devem "conversar"), entao o cubit e recriado
/// quando a conta, o time OU o modo selecionado mudam. So existe UM canal
/// Realtime (o do time desta tela, compartilhado pelos dois modos -- o
/// payload de cada evento ja diz a que (time, modo) ele se refere quando
/// isso importa).
class MatchmakingCubit extends Cubit<MatchmakingState> {
  MatchmakingCubit(
    this._repository,
    this._logger,
    this._cooldownStore, {
    required this.fcAccountId,
    required this.teamId,
    required this.mode,
  }) : super(const MatchmakingState());

  static const Duration invalidationDebounce = Duration(milliseconds: 200);

  final MatchmakingRepository _repository;
  final AppLogger _logger;
  final SearchCooldownStore _cooldownStore;
  final String fcAccountId;
  final String teamId;
  final GameMode mode;

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
      var snapshot = await _repository.getMyStatus(
        fcAccountId: fcAccountId,
        teamId: teamId,
        mode: mode,
      );
      if (_isStale(generation)) {
        return;
      }
      // searchingElsewhere e sempre sobre a PROPRIA conta (a RPC filtra por
      // fc_account_id). Quando o time da sessao "de outro lugar" e o MESMO
      // desta tela, so pode ser sobra de um modo que essa mesma conta
      // acabou de sair -- nunca e legitimamente "outra pessoa" nem "outro
      // time de verdade" (isso teria teamId diferente). Cleanup best-effort
      // do close() do cubit anterior e fire-and-forget (nao atrasa o
      // dispose), entao esta primeira leitura do cubit novo pode facilmente
      // vencer a corrida e ainda ver a busca antiga como SEARCHING -- em
      // vez de mostrar o banner de bloqueio pro usuario por causa disso,
      // termina a limpeza aqui e reconsulta antes de emitir.
      if (snapshot.searchingElsewhere?.teamId == teamId) {
        await _cancelStaleElsewhereSearch();
        if (_isStale(generation)) {
          return;
        }
        snapshot = await _repository.getMyStatus(
          fcAccountId: fcAccountId,
          teamId: teamId,
          mode: mode,
        );
        if (_isStale(generation)) {
          return;
        }
      }
      _emitSnapshot(snapshot, status: MatchmakingStatus.ready);
      // Cooldown local (ver SearchCooldownStore): o cubit acabou de nascer
      // (cooldownEndsAt sempre null no estado inicial), entao se um
      // cancelamento anterior -- desta sessao ou de uma ja descartada,
      // por qualquer troca de conta/time/modo -- ainda estiver dentro dos
      // 30s, o botao "Buscar partida" precisa nascer ja bloqueado, nao
      // liberado ate a proxima acao.
      final storedCooldown = _cooldownStore.read(fcAccountId, teamId, mode.key);
      if (storedCooldown != null && DateTime.now().isBefore(storedCooldown)) {
        emit(state.copyWith(cooldownEndsAt: storedCooldown));
      }
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
    final wasSearchingByMe = state.snapshot?.isSearchingByMe ?? false;
    emit(state.copyWith(isRefreshing: true));
    try {
      final snapshot = await _repository.getMyStatus(
        fcAccountId: fcAccountId,
        teamId: teamId,
        mode: mode,
      );
      if (_isStale(generation)) {
        return;
      }
      // Eu estava buscando e uma releitura PASSIVA (nunca uma acao minha --
      // essa passa por _runAction, nunca por aqui) descobre que nao estou
      // mais nem buscando nem na fila: a unica forma disso acontecer sem eu
      // ter feito nada e o servidor ter expirado minha busca sozinho.
      final expiredSilently =
          wasSearchingByMe &&
          !snapshot.isSearchingByMe &&
          !snapshot.isQueuedByMe;
      _emitSnapshot(
        snapshot,
        status: MatchmakingStatus.ready,
        isRefreshing: false,
        expired: expiredSilently,
      );
      if (expiredSilently) {
        _setCooldown(DateTime.now().add(_cooldownDuration));
      }
    } on AppFailure {
      if (_isStale(generation)) {
        return;
      }
      emit(state.copyWith(isRefreshing: false));
    }
  }

  Future<bool> startSearch({String? fcSquadId}) async {
    final ok = await _runAction(
      () => _repository.requestSearch(
        fcAccountId: fcAccountId,
        teamId: teamId,
        fcSquadId: fcSquadId,
        mode: mode,
      ),
    );
    if (ok && !isClosed) {
      emit(state.copyWith(clearCooldown: true));
    }
    return ok;
  }

  static const Duration _cooldownDuration = Duration(seconds: 30);

  Future<bool> cancel() async {
    final ok = await _runAction(() => _repository.cancelSearch(fcAccountId));
    if (ok && !isClosed) {
      _setCooldown(DateTime.now().add(_cooldownDuration));
    }
    return ok;
  }

  Future<bool> leaveQueue() => _runAction(
    () => _repository.leaveQueue(
      fcAccountId: fcAccountId,
      teamId: teamId,
      mode: mode,
    ),
  );

  Future<bool> matchFound() async {
    final ok = await _runAction(
      () => _repository.reportMatchFound(fcAccountId),
    );
    if (ok && !isClosed) {
      _setCooldown(DateTime.now().add(_cooldownDuration));
    }
    return ok;
  }

  /// Emite o cooldown no estado E o persiste no [SearchCooldownStore] --
  /// sem o segundo passo, um cubit novo (proxima troca de conta/time/modo)
  /// nasceria sem saber que esse cooldown ainda esta rolando.
  void _setCooldown(DateTime endsAt) {
    emit(state.copyWith(cooldownEndsAt: endsAt));
    unawaited(_cooldownStore.write(fcAccountId, teamId, mode.key, endsAt));
  }

  Future<bool> requestPriority() async {
    if (state.isActionPending) {
      return false;
    }
    emit(state.copyWith(isActionPending: true, clearFailure: true));
    try {
      await _repository.requestPriority(
        fcAccountId: fcAccountId,
        teamId: teamId,
        mode: mode,
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
        final isCooldown =
            failure is GameFailure &&
            failure.reason == GameFailureReason.cooldown;
        final cooldownEndsAt = isCooldown
            ? DateTime.now().add(_cooldownDuration)
            : state.cooldownEndsAt;
        emit(
          state.copyWith(
            isActionPending: false,
            failure: failure,
            cooldownEndsAt: cooldownEndsAt,
          ),
        );
        if (isCooldown) {
          unawaited(
            _cooldownStore.write(
              fcAccountId,
              teamId,
              mode.key,
              cooldownEndsAt!,
            ),
          );
        }
      }
      return false;
    }
  }

  bool _isStale(int generation) => isClosed || generation != _loadGeneration;

  /// Direto no repository (nunca _runAction, que da emit -- load() ja esta
  /// emitindo o proprio ciclo loading/ready) e melhor esforco: se falhar,
  /// a proxima leitura ainda mostra o banner (pior caso e igual a antes
  /// desta correcao), mas load() nao trava por causa disso.
  Future<void> _cancelStaleElsewhereSearch() async {
    try {
      await _repository.cancelSearch(fcAccountId);
    } on AppFailure {
      // Ignorado de proposito -- ver doc comment acima.
    }
  }

  void _emitSnapshot(
    MyMatchmakingSnapshot snapshot, {
    required MatchmakingStatus status,
    bool? isActionPending,
    bool? isRefreshing,
    bool expired = false,
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
        expiredNonce: expired ? state.expiredNonce + 1 : state.expiredNonce,
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
    // Este cubit e recriado (dispose do antigo + create do novo) sempre que
    // modo, time ou conta mudam -- ver o comment da `key` em
    // MatchmakingSection. Sem isso, uma busca/fila ativa ficava "orfa": o
    // servidor continuava considerando a conta buscando/na fila do modo
    // antigo, sem nenhum widget escutando mais aquilo, ate expirar sozinha
    // -- e enquanto isso o usuario podia cair numa fila do modo novo so
    // porque o lock global da conta (uma busca ativa por vez) ainda via a
    // busca antiga como em andamento.
    //
    // Direto no repository (nunca _runAction, que da emit -- proibido apos
    // close()) e best-effort (fire-and-forget, mesmo padrao de outros
    // pontos do app): nao vale atrasar o dispose, e se falhar o pior caso e
    // a mesma situacao de hoje (expira sozinha).
    final snapshot = state.snapshot;
    if (snapshot != null && snapshot.isSearchingByMe) {
      unawaited(_repository.cancelSearch(fcAccountId));
      // Mesmo cooldown de um cancel() manual (ver _setCooldown) -- so que
      // sem emit (cubit ja fechando): direto no store, pra sobreviver e
      // ser lido pelo PROXIMO cubit dessa mesma conta+time+modo, seja
      // daqui a 2 segundos ou depois de passar por outras contas.
      unawaited(
        _cooldownStore.write(
          fcAccountId,
          teamId,
          mode.key,
          DateTime.now().add(_cooldownDuration),
        ),
      );
    } else if (snapshot != null && snapshot.isQueuedByMe) {
      unawaited(
        _repository.leaveQueue(
          fcAccountId: fcAccountId,
          teamId: teamId,
          mode: mode,
        ),
      );
    }
    return super.close();
  }
}
