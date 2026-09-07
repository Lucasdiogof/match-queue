import 'package:equatable/equatable.dart';

enum InviteStatus { valid, alreadyMember, invalid, revoked, expired, exhausted }

/// Preview publico de um convite, devolvido por resolve_team_invite. Nunca
/// carrega membros, emails ou dados internos do link -- soh o minimo para
/// montar a BottomSheet.
class InvitePreview extends Equatable {
  const InvitePreview({
    required this.status,
    this.teamId,
    this.teamName,
    this.teamTag,
    this.teamLogoUrl,
    this.memberCount,
    this.isAlreadyMember,
  });

  final InviteStatus status;
  final String? teamId;
  final String? teamName;
  final String? teamTag;
  final String? teamLogoUrl;
  final int? memberCount;
  final bool? isAlreadyMember;

  bool get isJoinable => status == InviteStatus.valid;

  @override
  List<Object?> get props => <Object?>[
    status,
    teamId,
    teamName,
    teamTag,
    teamLogoUrl,
    memberCount,
    isAlreadyMember,
  ];
}
