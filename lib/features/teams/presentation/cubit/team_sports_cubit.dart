import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_sports_dashboard.dart';
import 'package:fifa_queue/features/teams/domain/repositories/team_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum TeamSportsStatus { loading, ready, failure }

class TeamSportsState extends Equatable {
  const TeamSportsState({
    this.status = TeamSportsStatus.loading,
    this.dashboard,
    this.isRefreshing = false,
    this.failure,
  });

  final TeamSportsStatus status;
  final TeamSportsDashboard? dashboard;
  final bool isRefreshing;
  final AppFailure? failure;

  TeamSportsState copyWith({
    TeamSportsStatus? status,
    TeamSportsDashboard? dashboard,
    bool? isRefreshing,
    AppFailure? failure,
    bool clearFailure = false,
  }) => TeamSportsState(
    status: status ?? this.status,
    dashboard: dashboard ?? this.dashboard,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    dashboard,
    isRefreshing,
    failure,
  ];
}

/// Um cubit para a tela inteira do Time, não um por seção: resumo, ranking,
/// artilharia, WL, Rivals e atividade vêm da mesma chamada e mudam juntos.
/// Cinco cubits concorrentes só criariam cinco estados para sincronizar.
class TeamSportsCubit extends Cubit<TeamSportsState> {
  TeamSportsCubit(this._repository, {required this.teamId})
    : super(const TeamSportsState());

  final TeamRepository _repository;
  final String teamId;

  Future<void> load() async {
    emit(state.copyWith(status: TeamSportsStatus.loading, clearFailure: true));
    await _fetch();
  }

  /// Usado pelo pull-to-refresh e ao voltar de um resultado editado: não
  /// volta para o skeleton, então a tela não pisca a cada retorno.
  Future<void> refresh() async {
    emit(state.copyWith(isRefreshing: true));
    await _fetch();
  }

  Future<void> _fetch() async {
    try {
      final dashboard = await _repository.fetchSportsDashboard(teamId);
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: TeamSportsStatus.ready,
          dashboard: dashboard,
          isRefreshing: false,
          clearFailure: true,
        ),
      );
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: state.dashboard == null
                ? TeamSportsStatus.failure
                : TeamSportsStatus.ready,
            isRefreshing: false,
            failure: failure,
          ),
        );
      }
    }
  }

  Future<List<TeamPlayerLeaderboardEntry>> fullLeaderboard({
    required bool byAssists,
  }) async {
    try {
      return await _repository.fetchPlayerLeaderboard(
        teamId: teamId,
        byAssists: byAssists,
      );
    } on AppFailure {
      return const <TeamPlayerLeaderboardEntry>[];
    }
  }
}
