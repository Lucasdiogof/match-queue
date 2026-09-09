import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/teams/data/datasources/team_remote_data_source.dart';
import 'package:fifa_queue/features/teams/data/models/player_profile_model.dart';
import 'package:fifa_queue/features/teams/data/models/team_member_model.dart';
import 'package:fifa_queue/features/teams/data/models/team_member_status_model.dart';
import 'package:fifa_queue/features/teams/data/models/team_model.dart';
import 'package:fifa_queue/features/teams/data/models/team_sports_dashboard_model.dart';
import 'package:fifa_queue/features/teams/domain/entities/player_profile.dart';
import 'package:fifa_queue/features/teams/domain/entities/team.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_member_status.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_membership.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_sports_dashboard.dart';
import 'package:fifa_queue/features/teams/domain/repositories/team_repository.dart';

class SupabaseTeamRepository implements TeamRepository {
  const SupabaseTeamRepository(this._dataSource, this._errorMapper);

  final TeamRemoteDataSource _dataSource;
  final SupabaseErrorMapper _errorMapper;

  @override
  Future<List<UserTeam>> fetchMyTeams() => _guard(() async {
    final rows = await _dataSource.fetchMyMemberships(_requireUserId());
    return rows
        .where((row) => row[TeamMemberModel.embeddedTeam] != null)
        .map(TeamMemberModel.userTeamFromJson)
        .toList(growable: false);
  });

  @override
  Future<Team> createTeam({
    required String name,
    String? tag,
    Duration? defaultSearchDuration,
  }) => _guard(() async {
    final row = await _dataSource.createTeam(
      name: name,
      tag: tag,
      defaultSearchDurationSeconds: defaultSearchDuration?.inSeconds,
    );
    return TeamModel.fromJson(row);
  });

  @override
  Future<Team> updateTeam({
    required String teamId,
    String? name,
    String? tag,
    bool clearTag = false,
    Duration? defaultSearchDuration,
  }) => _guard(() async {
    final values = <String, dynamic>{
      TeamModel.columnName: ?name,
      if (clearTag) TeamModel.columnTag: null else TeamModel.columnTag: ?tag,
      if (defaultSearchDuration != null)
        TeamModel.columnSearchDuration: defaultSearchDuration.inSeconds,
    };
    if (values.isEmpty) {
      throw const TeamFailure(reason: TeamFailureReason.invalidName);
    }
    final row = await _dataSource.updateTeam(teamId: teamId, values: values);
    return TeamModel.fromJson(row);
  });

  @override
  Future<Team> updateSearchDuration({
    required String teamId,
    required Duration duration,
  }) => _guard(() async {
    final row = await _dataSource.updateSearchDuration(
      teamId: teamId,
      seconds: duration.inSeconds,
    );
    return TeamModel.fromJson(row);
  });

  @override
  Future<List<TeamMember>> fetchMembers(String teamId) => _guard(() async {
    final rows = await _dataSource.fetchMembers(teamId);
    return rows
        .where((row) => row[TeamMemberModel.embeddedProfile] != null)
        .map(TeamMemberModel.memberFromJson)
        .toList(growable: false);
  });

  @override
  Future<List<TeamMemberStatus>> fetchPlayerStatuses(String teamId) =>
      _guard(() async {
        final json = await _dataSource.getPlayerStatuses(teamId);
        return TeamMemberStatusModel.listFromResponse(json);
      });

  @override
  Future<PlayerProfile> fetchMemberProfile({
    required String teamId,
    required String userId,
    String? fcAccountId,
  }) => _guard(() async {
    final json = await _dataSource.getMemberProfile(
      teamId: teamId,
      userId: userId,
      fcAccountId: fcAccountId,
    );
    return PlayerProfileModel.fromJson(json);
  });

  String _requireUserId() {
    final userId = _dataSource.currentUserId;
    if (userId == null || userId.isEmpty) {
      throw const AuthFailure(reason: AuthFailureReason.sessionExpired);
    }
    return userId;
  }

  @override
  Future<TeamSportsDashboard> fetchSportsDashboard(String teamId) => _guard(
    () async => TeamSportsDashboardModel.fromJson(
      await _dataSource.getSportsDashboard(teamId),
    ),
  );

  @override
  Future<List<TeamPlayerLeaderboardEntry>> fetchPlayerLeaderboard({
    required String teamId,
    required bool byAssists,
    int limit = 50,
    int offset = 0,
  }) => _guard(
    () async => TeamSportsDashboardModel.leaderboardFromResponse(
      await _dataSource.getPlayerLeaderboard(
        teamId: teamId,
        byAssists: byAssists,
        limit: limit,
        offset: offset,
      ),
    ),
  );

  @override
  Future<Team> setTeamVisibility({
    required String teamId,
    required bool isPublic,
  }) => _guard(() async {
    final row = await _dataSource.setTeamVisibility(
      teamId: teamId,
      isPublic: isPublic,
    );
    return TeamModel.fromJson(row);
  });

  @override
  Future<List<PublicTeamSummary>> listPublicTeams({int limit = 50}) =>
      _guard(() async {
        final response = await _dataSource.listPublicTeams(limit: limit);
        return <PublicTeamSummary>[
          if (response is List)
            for (final entry in response)
              if (entry is Map)
                TeamModel.summaryFromJson(Map<String, dynamic>.from(entry)),
        ];
      });

  @override
  Future<PublicTeam> getPublicTeam(String teamId) => _guard(() async {
    final json = await _dataSource.getPublicTeam(teamId);
    return TeamModel.publicTeamFromJson(json);
  });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error) {
      throw _errorMapper.map(error);
    }
  }
}
