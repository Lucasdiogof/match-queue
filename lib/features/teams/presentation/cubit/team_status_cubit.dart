import 'dart:async';

import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/matchmaking_realtime_event.dart';
import 'package:fifa_queue/features/matchmaking/domain/repositories/matchmaking_repository.dart';
import 'package:fifa_queue/features/teams/domain/repositories/team_repository.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/team_status_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Status operacional dos membros de um time (IN_MATCH/SEARCHING/QUEUED/
/// RECENTLY_ACTIVE/OFFLINE). Escopado por time como MatchmakingCubit --
/// recriado a cada troca de time, nunca um singleton do app.
///
/// Reaproveita o MESMO canal de invalidacao do matchmaking
/// (MatchmakingRepository.watchTeam): IN_MATCH/SEARCHING/QUEUED mudam em
/// tempo real por causa disso. RECENTLY_ACTIVE/OFFLINE dependem so de
/// last_active_at, que ninguem empurra por evento -- por isso o refresh
/// periodico (nunca agressivo) e quem mantem esses dois tiers atualizados,
/// eventualmente consistentes por natureza.
class TeamStatusCubit extends Cubit<TeamStatusState> {
  TeamStatusCubit(
    this._teamRepository,
    this._matchmakingRepository, {
    required this.teamId,
  }) : super(const TeamStatusState());

  static const Duration _periodicRefreshInterval = Duration(seconds: 60);
  static const Duration _invalidationDebounce = Duration(milliseconds: 200);

  final TeamRepository _teamRepository;
  final MatchmakingRepository _matchmakingRepository;
  final String teamId;

  StreamSubscription<MatchmakingRealtimeEvent>? _events;
  Timer? _debounce;
  Timer? _periodicRefresh;

  Future<void> start() {
    _events ??= _matchmakingRepository
        .watchTeam(teamId)
        .listen(_onRealtimeEvent);
    _periodicRefresh = Timer.periodic(
      _periodicRefreshInterval,
      (_) => refreshSilently(),
    );
    return load();
  }

  Future<void> load() async {
    emit(state.copyWith(status: TeamStatusLoadStatus.loading, clearFailure: true));
    try {
      final members = await _teamRepository.fetchPlayerStatuses(teamId);
      if (!isClosed) {
        emit(
          state.copyWith(
            status: TeamStatusLoadStatus.ready,
            members: members,
            clearFailure: true,
          ),
        );
      }
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(
          state.copyWith(status: TeamStatusLoadStatus.failure, failure: failure),
        );
      }
    }
  }

  Future<void> refreshSilently() async {
    try {
      final members = await _teamRepository.fetchPlayerStatuses(teamId);
      if (!isClosed) {
        emit(
          state.copyWith(
            status: TeamStatusLoadStatus.ready,
            members: members,
            clearFailure: true,
          ),
        );
      }
    } on AppFailure {
      // silencioso -- refresh em segundo plano nunca interrompe a tela.
    }
  }

  void _onRealtimeEvent(MatchmakingRealtimeEvent event) {
    if (event is MatchmakingStateInvalidated) {
      _debounce?.cancel();
      _debounce = Timer(_invalidationDebounce, () {
        if (!isClosed) {
          unawaited(refreshSilently());
        }
      });
    }
  }

  @override
  Future<void> close() async {
    _debounce?.cancel();
    _periodicRefresh?.cancel();
    await _events?.cancel();
    return super.close();
  }
}
