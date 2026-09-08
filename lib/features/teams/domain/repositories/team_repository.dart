import 'package:fifa_queue/features/teams/domain/entities/team.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_member_status.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_membership.dart';

abstract interface class TeamRepository {
  Future<List<UserTeam>> fetchMyTeams();

  Future<Team> createTeam({
    required String name,
    String? tag,
    Duration? defaultSearchDuration,
  });

  Future<Team> updateTeam({
    required String teamId,
    String? name,
    String? tag,
    bool clearTag = false,
    Duration? defaultSearchDuration,
  });

  /// Único caminho de escrita da duração de busca -- nunca via [updateTeam],
  /// pra não ter duas formas concorrentes de gravar a mesma config.
  Future<Team> updateSearchDuration({
    required String teamId,
    required Duration duration,
  });

  Future<List<TeamMember>> fetchMembers(String teamId);

  Future<List<TeamMemberStatus>> fetchPlayerStatuses(String teamId);
}
