import 'package:fifa_queue/features/teams/domain/entities/team_member_status.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_role.dart';

class TeamMemberStatusModel {
  const TeamMemberStatusModel._();

  static List<TeamMemberStatus> listFromResponse(Map<String, dynamic> json) {
    final members = json['members'] as List<dynamic>? ?? const <dynamic>[];
    return members
        .whereType<Map<String, dynamic>>()
        .map(_fromJson)
        .toList(growable: false);
  }

  static TeamMemberStatus _fromJson(Map<String, dynamic> json) =>
      TeamMemberStatus(
        userId: '${json['user_id']}',
        displayName: '${json['display_name']}',
        avatarUrl: json['avatar_url'] as String?,
        role: TeamRole.fromKey(json['role']),
        status: PlayerOperationalStatus.fromKey(json['status']),
        lastActiveAt: json['last_active_at'] == null
            ? null
            : DateTime.parse('${json['last_active_at']}'),
        queuePosition: json['queue_position'] as int?,
      );
}
