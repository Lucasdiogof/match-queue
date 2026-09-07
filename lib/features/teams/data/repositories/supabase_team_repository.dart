import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/teams/data/datasources/team_remote_data_source.dart';
import 'package:fifa_queue/features/teams/data/models/team_member_model.dart';
import 'package:fifa_queue/features/teams/data/models/team_model.dart';
import 'package:fifa_queue/features/teams/domain/entities/team.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_membership.dart';
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
      if (clearTag)
        TeamModel.columnTag: null
      else
        TeamModel.columnTag: ?tag,
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
  Future<List<TeamMember>> fetchMembers(String teamId) => _guard(() async {
    final rows = await _dataSource.fetchMembers(teamId);
    return rows
        .where((row) => row[TeamMemberModel.embeddedProfile] != null)
        .map(TeamMemberModel.memberFromJson)
        .toList(growable: false);
  });

  String _requireUserId() {
    final userId = _dataSource.currentUserId;
    if (userId == null || userId.isEmpty) {
      throw const AuthFailure(reason: AuthFailureReason.sessionExpired);
    }
    return userId;
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error) {
      throw _errorMapper.map(error);
    }
  }
}
