import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/matchmaking_snapshot.dart';
import 'package:fifa_queue/features/matchmaking/domain/repositories/matchmaking_repository.dart';
import 'package:fifa_queue/features/matchmaking/presentation/cubit/matchmaking_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Estado de matchmaking de um time. Escopado por instancia a um teamId
/// (recriado pela Home quando o time selecionado muda), igual ao
/// InviteManagementCubit -- nunca um singleton do app.
class MatchmakingCubit extends Cubit<MatchmakingState> {
  MatchmakingCubit(this._repository, {required this.teamId})
    : super(const MatchmakingState());

  final MatchmakingRepository _repository;
  final String teamId;

  Future<void> load() async {
    emit(
      state.copyWith(status: MatchmakingStatus.loading, clearFailure: true),
    );
    try {
      final snapshot = await _repository.getState(teamId);
      _emitSnapshot(snapshot, status: MatchmakingStatus.ready);
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(
          state.copyWith(status: MatchmakingStatus.failure, failure: failure),
        );
      }
    }
  }

  /// Usado pelo refresh periodico e pelo retorno de foreground: nunca volta
  /// pro estado de loading (evitaria um flash de skeleton a cada 15-20s) e
  /// nunca propaga falha pra UI -- se a rede falhar por um instante o
  /// ultimo snapshot bom continua na tela ate a proxima tentativa.
  Future<void> refreshSilently() async {
    try {
      final snapshot = await _repository.getState(teamId);
      _emitSnapshot(snapshot, status: MatchmakingStatus.ready);
    } on AppFailure {
      // silencioso de proposito -- ver doc acima.
    }
  }

  Future<bool> startSearch() => _runAction(_repository.requestSearch);

  Future<bool> cancel() => _runAction(_repository.cancelSearch);

  Future<bool> matchFound() => _runAction(_repository.reportMatchFound);

  Future<bool> _runAction(
    Future<MatchmakingSnapshot> Function(String teamId) action,
  ) async {
    if (state.isActionPending) {
      return false;
    }
    emit(state.copyWith(isActionPending: true, clearFailure: true));
    try {
      final snapshot = await action(teamId);
      if (!isClosed) {
        _emitSnapshot(
          snapshot,
          status: MatchmakingStatus.ready,
          isActionPending: false,
        );
      }
      return true;
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(isActionPending: false, failure: failure));
      }
      return false;
    }
  }

  void _emitSnapshot(
    MatchmakingSnapshot snapshot, {
    required MatchmakingStatus status,
    bool? isActionPending,
  }) {
    if (isClosed) {
      return;
    }
    final offset = snapshot.serverNow.difference(DateTime.now());
    emit(
      state.copyWith(
        status: status,
        snapshot: snapshot,
        isActionPending: isActionPending,
        serverOffset: offset,
        clearFailure: true,
      ),
    );
  }
}
