import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/requests/domain/entities/requests_inbox.dart';

enum RequestsStatus { initial, loading, ready, failure }

class RequestsState extends Equatable {
  const RequestsState({
    this.status = RequestsStatus.initial,
    this.inbox = const RequestsInbox.empty(),
    this.failure,
    this.pendingActionIds = const <String>{},
  });

  final RequestsStatus status;
  final RequestsInbox inbox;
  final AppFailure? failure;

  /// IDs de pedido/convite com uma acao em voo -- desabilita os botoes so
  /// daquele card, sem travar a tela inteira.
  final Set<String> pendingActionIds;

  bool get isLoading => status == RequestsStatus.loading;

  RequestsState copyWith({
    RequestsStatus? status,
    RequestsInbox? inbox,
    AppFailure? failure,
    bool clearFailure = false,
    Set<String>? pendingActionIds,
  }) => RequestsState(
    status: status ?? this.status,
    inbox: inbox ?? this.inbox,
    failure: clearFailure ? null : (failure ?? this.failure),
    pendingActionIds: pendingActionIds ?? this.pendingActionIds,
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    inbox,
    failure,
    pendingActionIds,
  ];
}
