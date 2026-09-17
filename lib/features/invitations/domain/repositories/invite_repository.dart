import 'package:fifa_queue/features/invitations/domain/entities/invite_preview.dart';
import 'package:fifa_queue/features/invitations/domain/entities/join_team_result.dart';
import 'package:fifa_queue/features/invitations/domain/entities/team_invite.dart';

abstract interface class InviteRepository {
  Future<InvitePreview> resolveInvite(String code);

  Future<JoinTeamResult> joinTeam(String code);

  Future<TeamInvite> getOrCreateActiveInvite(String teamId);

  Future<TeamInvite> rotateInvite(String teamId);

  Future<void> revokeInvite(String teamId);
}
