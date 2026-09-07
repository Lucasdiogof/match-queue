import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/invitations/domain/repositories/invite_repository.dart';
import 'package:fifa_queue/features/invitations/domain/usecases/resolve_team_invite.dart';
import 'package:fifa_queue/features/invitations/presentation/cubit/invite_resolution_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Estado de "alguem abriu um link de convite": resolver o preview e,
/// mediante confirmacao explicita, entrar no time. Nao sabe nada sobre
/// TeamsCubit/SelectedTeam/auth -- quem orquestra a reacao a um join bem
/// sucedido e o widget que escuta este cubit (JoinTeamPage), nao ele mesmo.
class InviteResolutionCubit extends Cubit<InviteResolutionState> {
  InviteResolutionCubit(this._resolveTeamInvite, this._repository)
    : super(const InviteResolutionState());

  final ResolveTeamInvite _resolveTeamInvite;
  final InviteRepository _repository;

  String? _code;

  Future<void> resolve(String code) async {
    _code = code;
    emit(const InviteResolutionState());
    try {
      final preview = await _resolveTeamInvite(code);
      emit(
        InviteResolutionState(
          status: InviteResolutionStatus.resolved,
          preview: preview,
        ),
      );
    } on AppFailure catch (failure) {
      emit(
        InviteResolutionState(
          status: InviteResolutionStatus.failure,
          failure: failure,
        ),
      );
    }
  }

  Future<void> join() async {
    final code = _code;
    if (code == null || state.status != InviteResolutionStatus.resolved) {
      return;
    }
    emit(state.copyWith(status: InviteResolutionStatus.joining));
    try {
      final result = await _repository.joinTeam(code);
      if (!isClosed) {
        emit(
          state.copyWith(
            status: InviteResolutionStatus.joined,
            joinResult: result,
          ),
        );
      }
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: InviteResolutionStatus.failure,
            failure: failure,
          ),
        );
      }
    }
  }
}
