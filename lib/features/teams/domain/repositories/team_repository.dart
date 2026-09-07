import 'package:fifa_queue/features/teams/domain/entities/team.dart';
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

  Future<List<TeamMember>> fetchMembers(String teamId);
}
