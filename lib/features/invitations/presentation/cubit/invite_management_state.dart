import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/invitations/domain/entities/team_invite.dart';

enum InviteManagementStatus { loading, ready, failure }

class InviteManagementState extends Equatable {
  const InviteManagementState({
    this.status = InviteManagementStatus.loading,
    this.invite,
    this.failure,
    this.isRotating = false,
    this.isRevoking = false,
  });

  final InviteManagementStatus status;
  final TeamInvite? invite;
  final AppFailure? failure;
  final bool isRotating;
  final bool isRevoking;

  InviteManagementState copyWith({
    InviteManagementStatus? status,
    TeamInvite? invite,
    bool clearInvite = false,
    AppFailure? failure,
    bool clearFailure = false,
    bool? isRotating,
    bool? isRevoking,
  }) => InviteManagementState(
    status: status ?? this.status,
    invite: clearInvite ? null : (invite ?? this.invite),
    failure: clearFailure ? null : (failure ?? this.failure),
    isRotating: isRotating ?? this.isRotating,
    isRevoking: isRevoking ?? this.isRevoking,
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    invite,
    failure,
    isRotating,
    isRevoking,
  ];
}
