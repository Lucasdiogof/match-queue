import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_member_status.dart';

enum TeamStatusLoadStatus { loading, ready, failure }

class TeamStatusState extends Equatable {
  const TeamStatusState({
    this.status = TeamStatusLoadStatus.loading,
    this.members = const <TeamMemberStatus>[],
    this.failure,
  });

  final TeamStatusLoadStatus status;
  final List<TeamMemberStatus> members;
  final AppFailure? failure;

  int get activeCount => members
      .where((member) => member.status != PlayerOperationalStatus.offline)
      .length;

  TeamStatusState copyWith({
    TeamStatusLoadStatus? status,
    List<TeamMemberStatus>? members,
    AppFailure? failure,
    bool clearFailure = false,
  }) => TeamStatusState(
    status: status ?? this.status,
    members: members ?? this.members,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => <Object?>[status, members, failure];
}
