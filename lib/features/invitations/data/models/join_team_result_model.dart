import 'package:fifa_queue/features/invitations/domain/entities/join_team_result.dart';

class JoinTeamResultModel {
  const JoinTeamResultModel._();

  static JoinTeamResult fromJson(Map<String, dynamic> json) =>
      JoinTeamResult(
        alreadyMember: json['already_member'] == true,
        teamId: '${json['team_id']}',
        teamName: '${json['team_name']}',
        teamTag: json['team_tag'] as String?,
        role: '${json['role']}',
      );
}
