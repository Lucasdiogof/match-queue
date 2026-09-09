import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/teams/domain/entities/team.dart';
import 'package:fifa_queue/features/teams/domain/repositories/team_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum PublicTeamsStatus { initial, loading, ready, failure }

class PublicTeamsState extends Equatable {
  const PublicTeamsState({
    this.status = PublicTeamsStatus.initial,
    this.teams = const <PublicTeamSummary>[],
    this.failure,
  });

  final PublicTeamsStatus status;
  final List<PublicTeamSummary> teams;
  final AppFailure? failure;

  bool get isLoading => status == PublicTeamsStatus.loading;

  PublicTeamsState copyWith({
    PublicTeamsStatus? status,
    List<PublicTeamSummary>? teams,
    AppFailure? failure,
    bool clearFailure = false,
  }) => PublicTeamsState(
    status: status ?? this.status,
    teams: teams ?? this.teams,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => <Object?>[status, teams, failure];
}

/// Aba Explorar (Times): so times publicos, nunca inclui os privados -- a
/// RPC list_public_teams ja garante isso no servidor.
class PublicTeamsCubit extends Cubit<PublicTeamsState> {
  PublicTeamsCubit(this._repository) : super(const PublicTeamsState());

  final TeamRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: PublicTeamsStatus.loading, clearFailure: true));
    try {
      final teams = await _repository.listPublicTeams();
      if (!isClosed) {
        emit(
          state.copyWith(
            status: PublicTeamsStatus.ready,
            teams: teams,
            clearFailure: true,
          ),
        );
      }
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(
          state.copyWith(status: PublicTeamsStatus.failure, failure: failure),
        );
      }
    }
  }
}
