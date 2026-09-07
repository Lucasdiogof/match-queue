import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/invitations/domain/repositories/invite_repository.dart';
import 'package:fifa_queue/features/invitations/presentation/cubit/invite_management_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Estado de "sou membro deste time e quero ver/girar/desativar o link de
/// convite dele". Escopado por instancia a um teamId (criado de novo pela
/// tela Time quando o time selecionado muda), nao um singleton do app.
class InviteManagementCubit extends Cubit<InviteManagementState> {
  InviteManagementCubit(this._repository, {required this.teamId})
    : super(const InviteManagementState());

  final InviteRepository _repository;
  final String teamId;

  Future<void> load() async {
    emit(state.copyWith(status: InviteManagementStatus.loading, clearFailure: true));
    try {
      final invite = await _repository.getOrCreateActiveInvite(teamId);
      emit(
        state.copyWith(
          status: InviteManagementStatus.ready,
          invite: invite,
          clearFailure: true,
        ),
      );
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(status: InviteManagementStatus.failure, failure: failure));
      }
    }
  }

  Future<bool> rotate() async {
    if (state.isRotating || state.isRevoking) {
      return false;
    }
    emit(state.copyWith(isRotating: true, clearFailure: true));
    try {
      final invite = await _repository.rotateInvite(teamId);
      if (!isClosed) {
        emit(
          state.copyWith(
            status: InviteManagementStatus.ready,
            invite: invite,
            isRotating: false,
            clearFailure: true,
          ),
        );
      }
      return true;
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(isRotating: false, failure: failure));
      }
      return false;
    }
  }

  Future<bool> revoke() async {
    if (state.isRotating || state.isRevoking) {
      return false;
    }
    emit(state.copyWith(isRevoking: true, clearFailure: true));
    try {
      await _repository.revokeInvite(teamId);
      if (!isClosed) {
        emit(
          state.copyWith(
            status: InviteManagementStatus.ready,
            clearInvite: true,
            isRevoking: false,
            clearFailure: true,
          ),
        );
      }
      return true;
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(isRevoking: false, failure: failure));
      }
      return false;
    }
  }
}
