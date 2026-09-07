import 'package:equatable/equatable.dart';
import 'package:fifa_queue/features/profile/domain/entities/profile.dart';
import 'package:fifa_queue/features/teams/domain/entities/team.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_role.dart';

class TeamMembership extends Equatable {
  const TeamMembership({
    required this.teamId,
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  final String teamId;
  final String userId;
  final TeamRole role;
  final DateTime joinedAt;

  @override
  List<Object?> get props => <Object?>[teamId, userId, role, joinedAt];
}

class TeamMember extends Equatable {
  const TeamMember({required this.membership, required this.profile});

  final TeamMembership membership;
  final Profile profile;

  String get userId => membership.userId;

  TeamRole get role => membership.role;

  String get displayName => profile.displayName;

  @override
  List<Object?> get props => <Object?>[membership, profile];
}

class UserTeam extends Equatable {
  const UserTeam({
    required this.team,
    required this.role,
    required this.joinedAt,
  });

  final Team team;
  final TeamRole role;
  final DateTime joinedAt;

  String get id => team.id;

  bool get canManageTeam => role.canManageTeam;

  @override
  List<Object?> get props => <Object?>[team, role, joinedAt];
}
