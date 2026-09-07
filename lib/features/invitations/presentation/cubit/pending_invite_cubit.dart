import 'package:fifa_queue/features/invitations/domain/entities/pending_invite.dart';
import 'package:fifa_queue/features/invitations/domain/repositories/pending_invite_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PendingInviteCubit extends Cubit<PendingInvite?> {
  PendingInviteCubit(this._repository) : super(null);

  final PendingInviteRepository _repository;

  void restore() => emit(_repository.read());

  Future<void> capture(String code) async {
    if (!InviteCode.isValid(code)) {
      return;
    }
    await _repository.save(code);
    emit(_repository.read());
  }

  Future<void> consume() async {
    await _repository.clear();
    emit(null);
  }
}
