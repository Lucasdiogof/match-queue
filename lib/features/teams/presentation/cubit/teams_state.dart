import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_membership.dart';

enum TeamsStatus { initial, loading, ready, failure }

enum TeamMembersStatus { initial, loading, ready, failure }

class TeamsState extends Equatable {
  const TeamsState({
    this.status = TeamsStatus.initial,
    this.userId,
    this.teams = const <UserTeam>[],
    this.selectedTeamId,
    this.membersStatus = TeamMembersStatus.initial,
    this.members = const <TeamMember>[],
    this.failure,
    this.membersFailure,
    this.actionFailure,
    this.isSaving = false,
    this.cachedAt,
  });

  final TeamsStatus status;

  /// Usuário cujos times estao (ou estavam sendo) carregados -- usado so
  /// pra descartar uma resposta que chegou depois de trocar de conta.
  final String? userId;
  final List<UserTeam> teams;
  final String? selectedTeamId;
  final TeamMembersStatus membersStatus;
  final List<TeamMember> members;
  final AppFailure? failure;
  final AppFailure? membersFailure;
  final AppFailure? actionFailure;
  final bool isSaving;

  /// Preenchido enquanto [teams] veio do cache local e ainda nao foi
  /// revalidado no servidor; e a data da ultima atualizacao bem-sucedida.
  final DateTime? cachedAt;

  bool get isFromCache => cachedAt != null;

  bool get isLoading => status == TeamsStatus.loading;

  bool get isReady => status == TeamsStatus.ready;

  bool get hasTeams => teams.isNotEmpty;

  bool get hasMultipleTeams => teams.length > 1;

  UserTeam? get selectedTeam {
    final id = selectedTeamId;
    if (id == null) {
      return null;
    }
    for (final team in teams) {
      if (team.id == id) {
        return team;
      }
    }
    return null;
  }

  TeamsState copyWith({
    TeamsStatus? status,
    String? userId,
    bool clearUserId = false,
    List<UserTeam>? teams,
    String? selectedTeamId,
    bool clearSelectedTeamId = false,
    TeamMembersStatus? membersStatus,
    List<TeamMember>? members,
    AppFailure? failure,
    bool clearFailure = false,
    AppFailure? membersFailure,
    bool clearMembersFailure = false,
    AppFailure? actionFailure,
    bool clearActionFailure = false,
    bool? isSaving,
    DateTime? cachedAt,
    bool clearCachedAt = false,
  }) => TeamsState(
    status: status ?? this.status,
    userId: clearUserId ? null : (userId ?? this.userId),
    teams: teams ?? this.teams,
    selectedTeamId: clearSelectedTeamId
        ? null
        : (selectedTeamId ?? this.selectedTeamId),
    membersStatus: membersStatus ?? this.membersStatus,
    members: members ?? this.members,
    failure: clearFailure ? null : (failure ?? this.failure),
    membersFailure: clearMembersFailure
        ? null
        : (membersFailure ?? this.membersFailure),
    actionFailure: clearActionFailure
        ? null
        : (actionFailure ?? this.actionFailure),
    isSaving: isSaving ?? this.isSaving,
    cachedAt: clearCachedAt ? null : (cachedAt ?? this.cachedAt),
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    userId,
    teams,
    selectedTeamId,
    membersStatus,
    members,
    failure,
    membersFailure,
    actionFailure,
    isSaving,
    cachedAt,
  ];
}
