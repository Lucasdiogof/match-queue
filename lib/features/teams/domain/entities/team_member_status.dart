import 'package:equatable/equatable.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_role.dart';

enum PlayerOperationalStatus {
  inMatch,
  searching,
  queued,
  recentlyActive,
  offline;

  static PlayerOperationalStatus fromKey(Object? key) => switch (key) {
    'IN_MATCH' => PlayerOperationalStatus.inMatch,
    'SEARCHING' => PlayerOperationalStatus.searching,
    'QUEUED' => PlayerOperationalStatus.queued,
    'RECENTLY_ACTIVE' => PlayerOperationalStatus.recentlyActive,
    _ => PlayerOperationalStatus.offline,
  };
}

class TeamMemberStatus extends Equatable {
  const TeamMemberStatus({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.status,
    this.avatarUrl,
    this.lastActiveAt,
    this.queuePosition,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final TeamRole role;
  final PlayerOperationalStatus status;
  final DateTime? lastActiveAt;
  final int? queuePosition;

  @override
  List<Object?> get props => <Object?>[
    userId,
    displayName,
    avatarUrl,
    role,
    status,
    lastActiveAt,
    queuePosition,
  ];
}
