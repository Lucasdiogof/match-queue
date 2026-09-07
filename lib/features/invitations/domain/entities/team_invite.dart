import 'package:equatable/equatable.dart';

/// O link de convite de um time, do lado de quem gerencia (ver/copiar/
/// compartilhar/girar/desativar). Espelha public.team_invite_links.
class TeamInvite extends Equatable {
  const TeamInvite({
    required this.id,
    required this.teamId,
    required this.code,
    required this.isActive,
    required this.usageCount,
    required this.createdAt,
    this.expiresAt,
    this.maxUses,
    this.revokedAt,
  });

  final String id;
  final String teamId;
  final String code;
  final bool isActive;
  final int usageCount;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int? maxUses;
  final DateTime? revokedAt;

  @override
  List<Object?> get props => <Object?>[
    id,
    teamId,
    code,
    isActive,
    usageCount,
    createdAt,
    expiresAt,
    maxUses,
    revokedAt,
  ];
}
