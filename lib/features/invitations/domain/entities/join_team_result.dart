import 'package:equatable/equatable.dart';

/// Resultado de join_team_by_invite. already_member=true significa que o
/// chamador ja era membro -- nao houve nova membership nem incremento de uso.
class JoinTeamResult extends Equatable {
  const JoinTeamResult({
    required this.alreadyMember,
    required this.teamId,
    required this.teamName,
    required this.teamTag,
    required this.role,
  });

  final bool alreadyMember;
  final String teamId;
  final String teamName;
  final String? teamTag;
  final String role;

  @override
  List<Object?> get props => <Object?>[
    alreadyMember,
    teamId,
    teamName,
    teamTag,
    role,
  ];
}
