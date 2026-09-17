import 'package:fifa_queue/features/account/data/models/account_model.dart';
import 'package:fifa_queue/features/teams/data/models/team_model.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_membership.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_role.dart';

class TeamMemberModel {
  const TeamMemberModel._();

  static const String table = 'team_members';
  static const String columnTeamId = 'team_id';
  static const String columnUserId = 'user_id';
  static const String columnRole = 'role';
  static const String columnJoinedAt = 'joined_at';
  static const String embeddedTeam = 'team';
  /// Alias do embed PostgREST sobre a tabela `profiles` (a tabela do
  /// usuario no banco) -- nome de wire, nao o conceito removido.
  static const String embeddedAccount = 'profile';

  static TeamMembership membershipFromJson(Map<String, dynamic> json) =>
      TeamMembership(
        teamId: '${json[columnTeamId]}',
        userId: '${json[columnUserId]}',
        role: TeamRole.fromKey(json[columnRole]),
        joinedAt: TeamModel.parseDate(json[columnJoinedAt]),
      );

  static TeamMember memberFromJson(Map<String, dynamic> json) => TeamMember(
    membership: membershipFromJson(json),
    account: AccountModel.fromJson(
      Map<String, dynamic>.from(json[embeddedAccount] as Map),
    ),
  );

  static UserTeam userTeamFromJson(Map<String, dynamic> json) => UserTeam(
    team: TeamModel.fromJson(
      Map<String, dynamic>.from(json[embeddedTeam] as Map),
    ),
    role: TeamRole.fromKey(json[columnRole]),
    joinedAt: TeamModel.parseDate(json[columnJoinedAt]),
  );
}
