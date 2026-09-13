import 'package:fifa_queue/features/requests/domain/entities/requests_inbox.dart';

class RequestsInboxModel {
  const RequestsInboxModel._();

  static RequestsInbox fromJson(Map<String, dynamic> json) {
    final invitationsJson =
        json['invitations_received'] as List<dynamic>? ?? const <dynamic>[];
    final requestsJson =
        json['join_requests_to_review'] as List<dynamic>? ?? const <dynamic>[];

    return RequestsInbox(
      invitationsReceived: invitationsJson
          .whereType<Map<String, dynamic>>()
          .map(
            (row) => TeamInvitationSummary(
              id: '${row['id']}',
              teamId: '${row['team_id']}',
              teamName: '${row['team_name']}',
              teamTag: row['team_tag'] as String?,
              teamLogoUrl: row['team_logo_url'] as String?,
              memberCount: row['member_count'] as int? ?? 0,
              fcAccountName: row['fc_account_name'] as String?,
              createdAt: DateTime.parse('${row['created_at']}'),
            ),
          )
          .toList(growable: false),
      joinRequestsToReview: requestsJson
          .whereType<Map<String, dynamic>>()
          .map(
            (row) => TeamJoinRequestSummary(
              id: '${row['id']}',
              teamId: '${row['team_id']}',
              teamName: '${row['team_name']}',
              requesterUserId: '${row['requester_user_id']}',
              requesterDisplayName: '${row['requester_display_name']}',
              requesterAvatarUrl: row['requester_avatar_url'] as String?,
              fcAccountName: row['fc_account_name'] as String?,
              createdAt: DateTime.parse('${row['created_at']}'),
            ),
          )
          .toList(growable: false),
    );
  }
}
