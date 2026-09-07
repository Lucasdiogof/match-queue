import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/invitations/domain/entities/invite_preview.dart';
import 'package:fifa_queue/features/invitations/domain/entities/join_team_result.dart';

enum InviteResolutionStatus { loading, resolved, joining, joined, failure }

class InviteResolutionState extends Equatable {
  const InviteResolutionState({
    this.status = InviteResolutionStatus.loading,
    this.preview,
    this.joinResult,
    this.failure,
  });

  final InviteResolutionStatus status;
  final InvitePreview? preview;
  final JoinTeamResult? joinResult;
  final AppFailure? failure;

  InviteResolutionState copyWith({
    InviteResolutionStatus? status,
    InvitePreview? preview,
    JoinTeamResult? joinResult,
    AppFailure? failure,
    bool clearFailure = false,
  }) => InviteResolutionState(
    status: status ?? this.status,
    preview: preview ?? this.preview,
    joinResult: joinResult ?? this.joinResult,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => <Object?>[status, preview, joinResult, failure];
}
