import 'dart:async';

import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/requests/domain/entities/requests_inbox.dart';
import 'package:fifa_queue/features/requests/domain/repositories/requests_repository.dart';
import 'package:fifa_queue/features/requests/presentation/cubit/requests_cubit.dart';
import 'package:fifa_queue/features/requests/presentation/cubit/requests_state.dart';
import 'package:flutter_test/flutter_test.dart';

TeamJoinRequestSummary _joinRequest(String id) => TeamJoinRequestSummary(
  id: id,
  teamId: 'team-1',
  teamName: 'Lucksrei FC',
  requesterUserId: 'user-$id',
  requesterDisplayName: 'Jogador $id',
  createdAt: DateTime.utc(2026, 9, 13),
);

TeamInvitationSummary _invitation(String id) => TeamInvitationSummary(
  id: id,
  teamId: 'team-1',
  teamName: 'Lucksrei FC',
  memberCount: 5,
  createdAt: DateTime.utc(2026, 9, 13),
);

/// Fake com comportamento configuravel por teste. Metodos nao usados caem
/// no noSuchMethod (mesmo padrao de player_picker_eligibility_test.dart) --
/// a interface tem muito mais superficie do que qualquer teste isolado
/// precisa.
class _FakeRequestsRepository implements RequestsRepository {
  _FakeRequestsRepository({RequestsInbox? inbox})
    : inbox = inbox ?? const RequestsInbox.empty();

  RequestsInbox inbox;
  AppFailure? failureToThrow;
  AppFailure? inboxFailureToThrow;
  int callCount = 0;
  final List<String> approvedIds = <String>[];
  final List<String> rejectedIds = <String>[];
  final List<String> acceptedIds = <String>[];
  final List<String> declinedIds = <String>[];
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Completer opcional para segurar a acao em voo e testar duplicidade.
  Completer<void>? actionGate;

  void emitChange() => _changes.add(null);

  @override
  Future<RequestsInbox> fetchInbox() async {
    callCount++;
    final failure = inboxFailureToThrow;
    if (failure != null) {
      throw failure;
    }
    return inbox;
  }

  Future<void> _maybeGate() async {
    final gate = actionGate;
    if (gate != null) {
      await gate.future;
    }
    final failure = failureToThrow;
    if (failure != null) {
      throw failure;
    }
  }

  @override
  Future<void> approveJoinRequest(String requestId) async {
    await _maybeGate();
    approvedIds.add(requestId);
  }

  @override
  Future<void> rejectJoinRequest(String requestId) async {
    await _maybeGate();
    rejectedIds.add(requestId);
  }

  @override
  Future<void> respondInvitation({
    required String invitationId,
    required bool accept,
  }) async {
    await _maybeGate();
    if (accept) {
      acceptedIds.add(invitationId);
    } else {
      declinedIds.add(invitationId);
    }
  }

  @override
  Stream<void> watchChanges() => _changes.stream;

  @override
  Never noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

void main() {
  group('RequestsCubit.load', () {
    test('popula o inbox e fica ready', () async {
      final repository = _FakeRequestsRepository(
        inbox: RequestsInbox(
          invitationsReceived: <TeamInvitationSummary>[_invitation('inv-1')],
          joinRequestsToReview: <TeamJoinRequestSummary>[_joinRequest('req-1')],
        ),
      );
      final cubit = RequestsCubit(repository);

      await cubit.load();

      expect(cubit.state.status, RequestsStatus.ready);
      expect(cubit.state.inbox.pendingCount, 2);
    });

    test(
      'falha do repositorio vira failure sem apagar o inbox anterior',
      () async {
        final repository = _FakeRequestsRepository(
          inbox: RequestsInbox(
            invitationsReceived: const <TeamInvitationSummary>[],
            joinRequestsToReview: <TeamJoinRequestSummary>[
              _joinRequest('req-1'),
            ],
          ),
        );
        final cubit = RequestsCubit(repository);
        await cubit.load();

        repository.inboxFailureToThrow = const TeamFailure(
          reason: TeamFailureReason.notFound,
        );
        await cubit.load();

        expect(cubit.state.inbox.joinRequestsToReview, hasLength(1));
      },
    );
  });

  group('RequestsCubit acoes', () {
    test('aprovar um pedido remove ele da lista em caso de sucesso', () async {
      final repository = _FakeRequestsRepository(
        inbox: RequestsInbox(
          invitationsReceived: const <TeamInvitationSummary>[],
          joinRequestsToReview: <TeamJoinRequestSummary>[
            _joinRequest('req-1'),
            _joinRequest('req-2'),
          ],
        ),
      );
      final cubit = RequestsCubit(repository);
      await cubit.load();

      await cubit.approveJoinRequest('req-1');

      expect(repository.approvedIds, <String>['req-1']);
      expect(cubit.state.inbox.joinRequestsToReview.map((r) => r.id), <String>[
        'req-2',
      ]);
      expect(cubit.state.pendingActionIds, isEmpty);
    });

    test('recusar um pedido remove ele da lista em caso de sucesso', () async {
      final repository = _FakeRequestsRepository(
        inbox: RequestsInbox(
          invitationsReceived: const <TeamInvitationSummary>[],
          joinRequestsToReview: <TeamJoinRequestSummary>[_joinRequest('req-1')],
        ),
      );
      final cubit = RequestsCubit(repository);
      await cubit.load();

      await cubit.rejectJoinRequest('req-1');

      expect(repository.rejectedIds, <String>['req-1']);
      expect(cubit.state.inbox.joinRequestsToReview, isEmpty);
    });

    test('aceitar um convite remove ele da lista em caso de sucesso', () async {
      final repository = _FakeRequestsRepository(
        inbox: RequestsInbox(
          invitationsReceived: <TeamInvitationSummary>[_invitation('inv-1')],
          joinRequestsToReview: const <TeamJoinRequestSummary>[],
        ),
      );
      final cubit = RequestsCubit(repository);
      await cubit.load();

      await cubit.acceptInvitation('inv-1');

      expect(repository.acceptedIds, <String>['inv-1']);
      expect(cubit.state.inbox.invitationsReceived, isEmpty);
    });

    test('recusar um convite remove ele da lista em caso de sucesso', () async {
      final repository = _FakeRequestsRepository(
        inbox: RequestsInbox(
          invitationsReceived: <TeamInvitationSummary>[_invitation('inv-1')],
          joinRequestsToReview: const <TeamJoinRequestSummary>[],
        ),
      );
      final cubit = RequestsCubit(repository);
      await cubit.load();

      await cubit.declineInvitation('inv-1');

      expect(repository.declinedIds, <String>['inv-1']);
      expect(cubit.state.inbox.invitationsReceived, isEmpty);
    });

    test('falha na acao mantem o item na lista e expoe a falha', () async {
      final repository =
          _FakeRequestsRepository(
              inbox: RequestsInbox(
                invitationsReceived: const <TeamInvitationSummary>[],
                joinRequestsToReview: <TeamJoinRequestSummary>[
                  _joinRequest('req-1'),
                ],
              ),
            )
            ..failureToThrow = const TeamFailure(
              reason: TeamFailureReason.requestNotFound,
            );
      final cubit = RequestsCubit(repository);
      await cubit.load();

      await cubit.approveJoinRequest('req-1');

      expect(cubit.state.inbox.joinRequestsToReview, hasLength(1));
      expect(cubit.state.failure, isA<TeamFailure>());
      expect(cubit.state.pendingActionIds, isEmpty);
    });

    test(
      'uma segunda chamada pro mesmo id enquanto a primeira esta em voo e ignorada',
      () async {
        final repository = _FakeRequestsRepository(
          inbox: RequestsInbox(
            invitationsReceived: const <TeamInvitationSummary>[],
            joinRequestsToReview: <TeamJoinRequestSummary>[
              _joinRequest('req-1'),
            ],
          ),
        );
        repository.actionGate = Completer<void>();
        final cubit = RequestsCubit(repository);
        await cubit.load();

        final first = cubit.approveJoinRequest('req-1');
        final second = cubit.approveJoinRequest('req-1');

        expect(cubit.state.pendingActionIds, <String>{'req-1'});

        repository.actionGate!.complete();
        await first;
        await second;

        expect(repository.approvedIds, <String>['req-1']);
      },
    );
  });

  group('RequestsCubit.start/stop', () {
    test('start carrega o inbox e reage a mudancas do Realtime', () async {
      final repository = _FakeRequestsRepository(
        inbox: RequestsInbox(
          invitationsReceived: const <TeamInvitationSummary>[],
          joinRequestsToReview: <TeamJoinRequestSummary>[_joinRequest('req-1')],
        ),
      );
      final cubit = RequestsCubit(repository);

      await cubit.start();
      expect(repository.callCount, 1);

      repository.inbox = RequestsInbox(
        invitationsReceived: const <TeamInvitationSummary>[],
        joinRequestsToReview: <TeamJoinRequestSummary>[
          _joinRequest('req-1'),
          _joinRequest('req-2'),
        ],
      );
      repository.emitChange();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.inbox.joinRequestsToReview, hasLength(2));

      await cubit.stop();
    });
  });
}
