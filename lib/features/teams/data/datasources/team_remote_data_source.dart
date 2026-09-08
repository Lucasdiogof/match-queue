import 'package:fifa_queue/features/profile/data/models/profile_model.dart';
import 'package:fifa_queue/features/teams/data/models/team_member_model.dart';
import 'package:fifa_queue/features/teams/data/models/team_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class TeamRemoteDataSource {
  String? get currentUserId;

  Future<List<Map<String, dynamic>>> fetchMyMemberships(String userId);

  Future<Map<String, dynamic>> createTeam({
    required String name,
    String? tag,
    int? defaultSearchDurationSeconds,
  });

  Future<Map<String, dynamic>> updateTeam({
    required String teamId,
    required Map<String, dynamic> values,
  });

  Future<Map<String, dynamic>> updateSearchDuration({
    required String teamId,
    required int seconds,
  });

  Future<List<Map<String, dynamic>>> fetchMembers(String teamId);

  Future<Map<String, dynamic>> getPlayerStatuses(String teamId);

  Future<Map<String, dynamic>> getMemberProfile({
    required String teamId,
    required String userId,
    String? fcAccountId,
  });
}

class SupabaseTeamRemoteDataSource implements TeamRemoteDataSource {
  const SupabaseTeamRemoteDataSource(this._client);

  static const String createTeamFunction = 'create_team';

  final SupabaseClient _client;

  SupabaseQueryBuilder get _members => _client.from(TeamMemberModel.table);

  SupabaseQueryBuilder get _teams => _client.from(TeamModel.table);

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<List<Map<String, dynamic>>> fetchMyMemberships(String userId) async {
    final rows = await _members
        .select(
          '${TeamMemberModel.columnRole}, '
          '${TeamMemberModel.columnJoinedAt}, '
          '${TeamMemberModel.embeddedTeam}:${TeamModel.table}(*)',
        )
        .eq(TeamMemberModel.columnUserId, userId)
        // ascending: true explicito -- o default do postgrest-dart e
        // DESCENDENTE. Sem isto "meus times" vinha do mais novo pro mais
        // antigo e o fallback de selecao pulava para o time recem-criado.
        .order(TeamMemberModel.columnJoinedAt, ascending: true)
        .order(TeamMemberModel.columnTeamId, ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<Map<String, dynamic>> createTeam({
    required String name,
    String? tag,
    int? defaultSearchDurationSeconds,
  }) async {
    final response = await _client.rpc<dynamic>(
      createTeamFunction,
      params: <String, dynamic>{
        'p_name': name,
        'p_tag': tag,
        'p_default_search_duration_seconds': ?defaultSearchDurationSeconds,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<Map<String, dynamic>> updateTeam({
    required String teamId,
    required Map<String, dynamic> values,
  }) async {
    final row = await _teams
        .update(values)
        .eq(TeamModel.columnId, teamId)
        .select()
        .single();
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<Map<String, dynamic>> updateSearchDuration({
    required String teamId,
    required int seconds,
  }) async {
    final response = await _client.rpc<dynamic>(
      'update_team_search_duration',
      params: <String, dynamic>{'p_team_id': teamId, 'p_seconds': seconds},
    );
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<Map<String, dynamic>> getPlayerStatuses(String teamId) async {
    final response = await _client.rpc<dynamic>(
      'get_team_player_statuses',
      params: <String, dynamic>{'p_team_id': teamId},
    );
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<Map<String, dynamic>> getMemberProfile({
    required String teamId,
    required String userId,
    String? fcAccountId,
  }) async {
    final response = await _client.rpc<dynamic>(
      'get_team_member_profile',
      params: <String, dynamic>{
        'p_team_id': teamId,
        'p_user_id': userId,
        'p_fc_account_id': fcAccountId,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMembers(String teamId) async {
    final rows = await _members
        .select(
          '${TeamMemberModel.columnTeamId}, '
          '${TeamMemberModel.columnUserId}, '
          '${TeamMemberModel.columnRole}, '
          '${TeamMemberModel.columnJoinedAt}, '
          '${TeamMemberModel.embeddedProfile}:${ProfileModel.table}(*)',
        )
        .eq(TeamMemberModel.columnTeamId, teamId)
        // A ordem do enum team_role e OWNER, ADMIN, PLAYER; ascendente
        // coloca o dono no topo. Com o default descendente do
        // postgrest-dart a lista vinha invertida, com o OWNER por ultimo.
        .order(TeamMemberModel.columnRole, ascending: true)
        .order(TeamMemberModel.columnJoinedAt, ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }
}
