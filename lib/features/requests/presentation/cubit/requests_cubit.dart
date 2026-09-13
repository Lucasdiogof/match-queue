import 'dart:async';

import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/requests/domain/entities/requests_inbox.dart';
import 'package:fifa_queue/features/requests/domain/repositories/requests_repository.dart';
import 'package:fifa_queue/features/requests/presentation/cubit/requests_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Singleton de app: alimenta tanto a tela Solicitacoes quanto o badge da
/// bottom nav, que precisa saber o total pendente mesmo fora da tela.
class RequestsCubit extends Cubit<RequestsState> {
  RequestsCubit(this._repository) : super(const RequestsState());

  final RequestsRepository _repository;
  StreamSubscription<void>? _revisionSubscription;

  /// Carrega o inbox e comeca a ouvir o Realtime -- chamado no login (a
  /// stream e por usuario, entao so faz sentido depois que ha sessao).
  Future<void> start() async {
    await load();
    _revisionSubscription ??= _repository.watchChanges().listen(
      (_) => refresh(),
    );
  }

  /// Para de ouvir o Realtime -- chamado no logout, pra nao manter um canal
  /// vivo apontando pro user_id da sessao que acabou de sair.
  Future<void> stop() async {
    await _revisionSubscription?.cancel();
    _revisionSubscription = null;
  }

  @override
  Future<void> close() {
    unawaited(_revisionSubscription?.cancel());
    return super.close();
  }

  Future<void> load() async {
    emit(state.copyWith(status: RequestsStatus.loading, clearFailure: true));
    try {
      final inbox = await _repository.fetchInbox();
      if (!isClosed) {
        emit(state.copyWith(status: RequestsStatus.ready, inbox: inbox));
      }
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(status: RequestsStatus.failure, failure: failure));
      }
    }
  }

  Future<void> refresh() => load();

  /// Badge nunca pode sobreviver a troca de sessao (mesma regra do
  /// NotificationUnreadCubit).
  void clear() => emit(const RequestsState());

  Future<void> approveJoinRequest(String requestId) =>
      _runAction(requestId, () => _repository.approveJoinRequest(requestId));

  Future<void> rejectJoinRequest(String requestId) =>
      _runAction(requestId, () => _repository.rejectJoinRequest(requestId));

  Future<void> acceptInvitation(String invitationId) => _runAction(
    invitationId,
    () =>
        _repository.respondInvitation(invitationId: invitationId, accept: true),
  );

  Future<void> declineInvitation(String invitationId) => _runAction(
    invitationId,
    () => _repository.respondInvitation(
      invitationId: invitationId,
      accept: false,
    ),
  );

  /// Executa a acao e, so em caso de sucesso, remove o item da lista local
  /// (evita reconciliar com um refresh completo pra uma unica linha).
  Future<void> _runAction(String id, Future<void> Function() action) async {
    if (state.pendingActionIds.contains(id)) {
      return;
    }
    emit(
      state.copyWith(
        pendingActionIds: <String>{...state.pendingActionIds, id},
        clearFailure: true,
      ),
    );
    try {
      await action();
      if (!isClosed) {
        emit(
          state.copyWith(
            inbox: RequestsInbox(
              invitationsReceived: state.inbox.invitationsReceived
                  .where((i) => i.id != id)
                  .toList(growable: false),
              joinRequestsToReview: state.inbox.joinRequestsToReview
                  .where((r) => r.id != id)
                  .toList(growable: false),
            ),
            pendingActionIds: state.pendingActionIds.difference(<String>{id}),
          ),
        );
      }
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(
          state.copyWith(
            failure: failure,
            pendingActionIds: state.pendingActionIds.difference(<String>{id}),
          ),
        );
      }
    }
  }
}
