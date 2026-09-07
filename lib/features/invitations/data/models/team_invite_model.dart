import 'package:fifa_queue/features/invitations/domain/entities/team_invite.dart';

class TeamInviteModel {
  const TeamInviteModel._();

  static const String columnId = 'id';
  static const String columnTeamId = 'team_id';
  static const String columnCode = 'code';
  static const String columnIsActive = 'is_active';
  static const String columnExpiresAt = 'expires_at';
  static const String columnMaxUses = 'max_uses';
  static const String columnUsageCount = 'usage_count';
  static const String columnCreatedAt = 'created_at';
  static const String columnRevokedAt = 'revoked_at';

  static TeamInvite fromJson(Map<String, dynamic> json) => TeamInvite(
    id: '${json[columnId]}',
    teamId: '${json[columnTeamId]}',
    code: '${json[columnCode]}',
    isActive: json[columnIsActive] == true,
    usageCount: json[columnUsageCount] is int
        ? json[columnUsageCount] as int
        : 0,
    createdAt: _parseDate(json[columnCreatedAt]) ?? DateTime.now().toUtc(),
    expiresAt: _parseDate(json[columnExpiresAt]),
    maxUses: json[columnMaxUses] is int ? json[columnMaxUses] as int : null,
    revokedAt: _parseDate(json[columnRevokedAt]),
  );

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;
}
