import 'package:fifa_queue/features/invitations/domain/entities/invite_preview.dart';

class InvitePreviewModel {
  const InvitePreviewModel._();

  static InvitePreview fromJson(Map<String, dynamic> json) => InvitePreview(
    status: _statusFrom(json['status']),
    teamId: json['team_id'] as String?,
    teamName: json['team_name'] as String?,
    teamTag: json['team_tag'] as String?,
    teamLogoUrl: json['team_logo_url'] as String?,
    memberCount: json['member_count'] is int
        ? json['member_count'] as int
        : null,
    isAlreadyMember: json['is_already_member'] as bool?,
  );

  static InviteStatus _statusFrom(Object? value) => switch (value) {
    'valid' => InviteStatus.valid,
    'already_member' => InviteStatus.alreadyMember,
    'revoked' => InviteStatus.revoked,
    'expired' => InviteStatus.expired,
    'exhausted' => InviteStatus.exhausted,
    _ => InviteStatus.invalid,
  };
}
