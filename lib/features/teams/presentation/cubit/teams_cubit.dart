import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/teams/data/selected_team_store.dart';
import 'package:fifa_queue/features/teams/domain/entities/team.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_membership.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_role.dart';
import 'package:fifa_queue/features/teams/domain/repositories/team_repository.dart';
import 'package:fifa_queue/features/teams/domain/usecases/create_team.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeamsCubit extends Cubit<TeamsState> {
  TeamsCubit(this._repository, this._createTeam, this._selectedTeamStore)
    : super(const TeamsState());

  final TeamRepository _repository;
  final CreateTeam _createTeam;
  final SelectedTeamStore _selectedTeamStore;

  String? _userId;

  Future<void> load({required String userId}) async {
    _userId = userId;
    emit(state.copyWith(status: TeamsStatus.loading, clearFailure: true));
    try {
      final teams = await _repository.fetchMyTeams();
      final selectedId = _resolveSelectedId(teams, userId);
      emit(
        state.copyWith(
          status: TeamsStatus.ready,
          teams: teams,
          selectedTeamId: selectedId,
          clearSelectedTeamId: selectedId == null,
          clearFailure: true,
        ),
      );
      if (selectedId != null) {
        await _loadMembers(selectedId);
      } else {
        emit(
          state.copyWith(
            membersStatus: TeamMembersStatus.initial,
            members: const <TeamMember>[],
            clearMembersFailure: true,
          ),
        );
      }
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(status: TeamsStatus.failure, failure: failure));
      }
    }
  }

  Future<void> refresh() async {
    final userId = _userId;
    if (userId == null) {
      return;
    }
    await load(userId: userId);
  }

  Future<void> selectTeam(String teamId) async {
    if (state.selectedTeamId == teamId) {
      return;
    }
    if (!state.teams.any((team) => team.id == teamId)) {
      return;
    }
    emit(state.copyWith(selectedTeamId: teamId));
    await _persistSelected(teamId);
    await _loadMembers(teamId);
  }

  Future<Team?> createTeam({
    required String name,
    String? tag,
    Duration? defaultSearchDuration,
  }) async {
    if (state.isSaving) {
      return null;
    }
    emit(state.copyWith(isSaving: true, clearActionFailure: true));
    try {
      final team = await _createTeam(
        name: name,
        tag: tag,
        defaultSearchDuration: defaultSearchDuration,
      );
      final teams = <UserTeam>[
        ...state.teams,
        UserTeam(team: team, role: TeamRole.owner, joinedAt: team.createdAt),
      ];
      emit(
        state.copyWith(
          status: TeamsStatus.ready,
          teams: teams,
          selectedTeamId: team.id,
          isSaving: false,
          clearActionFailure: true,
        ),
      );
      await _persistSelected(team.id);
      await _loadMembers(team.id);
      return team;
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(isSaving: false, actionFailure: failure));
      }
      return null;
    }
  }

  Future<bool> updateTeam({
    required String teamId,
    String? name,
    String? tag,
    bool clearTag = false,
    Duration? defaultSearchDuration,
  }) async {
    if (state.isSaving) {
      return false;
    }
    emit(state.copyWith(isSaving: true, clearActionFailure: true));
    try {
      final updated = await _repository.updateTeam(
        teamId: teamId,
        name: name,
        tag: tag,
        clearTag: clearTag,
        defaultSearchDuration: defaultSearchDuration,
      );
      final teams = state.teams
          .map(
            (userTeam) => userTeam.id == teamId
                ? UserTeam(
                    team: updated,
                    role: userTeam.role,
                    joinedAt: userTeam.joinedAt,
                  )
                : userTeam,
          )
          .toList(growable: false);
      emit(state.copyWith(teams: teams, isSaving: false));
      return true;
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(isSaving: false, actionFailure: failure));
      }
      return false;
    }
  }

  void clearActionFailure() {
    if (state.actionFailure != null) {
      emit(state.copyWith(clearActionFailure: true));
    }
  }

  void clear() {
    _userId = null;
    emit(const TeamsState());
  }

  Future<void> _loadMembers(String teamId) async {
    emit(
      state.copyWith(
        membersStatus: TeamMembersStatus.loading,
        clearMembersFailure: true,
      ),
    );
    try {
      final members = await _repository.fetchMembers(teamId);
      if (!isClosed && state.selectedTeamId == teamId) {
        emit(
          state.copyWith(
            membersStatus: TeamMembersStatus.ready,
            members: members,
            clearMembersFailure: true,
          ),
        );
      }
    } on AppFailure catch (failure) {
      if (!isClosed && state.selectedTeamId == teamId) {
        emit(
          state.copyWith(
            membersStatus: TeamMembersStatus.failure,
            membersFailure: failure,
          ),
        );
      }
    }
  }

  String? _resolveSelectedId(List<UserTeam> teams, String userId) {
    if (teams.isEmpty) {
      return null;
    }
    final persisted = _selectedTeamStore.read(userId);
    if (persisted != null && teams.any((team) => team.id == persisted)) {
      return persisted;
    }
    return teams.first.id;
  }

  Future<void> _persistSelected(String? teamId) async {
    final userId = _userId;
    if (userId == null) {
      return;
    }
    await _selectedTeamStore.write(userId, teamId);
  }
}
