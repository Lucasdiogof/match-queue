import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/my_matchmaking_status.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime.utc(2026, 10, 17, 21);

MyMatchmakingSnapshot _snap(
  MyMatchmakingStatus status, {
  SearchingElsewhere? elsewhere,
  List<QueueEntry> queue = const [],
  int? position,
}) => MyMatchmakingSnapshot(
  userId: 'u1',
  teamId: 't1',
  myStatus: status,
  serverNow: _now,
  myPosition: position,
  searchingElsewhere: elsewhere,
  queue: queue,
);

void main() {
  group('MyMatchmakingSnapshot', () {
    test('cada estado liga exatamente um indicador', () {
      final searching = _snap(MyMatchmakingStatus.searching);
      expect(
        [searching.isSearchingByMe, searching.isQueuedByMe, searching.isIdle],
        [true, false, false],
      );

      final queued = _snap(MyMatchmakingStatus.queued, position: 3);
      expect(
        [queued.isSearchingByMe, queued.isQueuedByMe, queued.isIdle],
        [false, true, false],
      );
      expect(queued.myPosition, 3);

      final none = _snap(MyMatchmakingStatus.none);
      expect(
        [none.isSearchingByMe, none.isQueuedByMe, none.isIdle],
        [false, false, true],
      );
    });

    test('ocupado em outro time quando há busca ativa noutro lugar', () {
      expect(_snap(MyMatchmakingStatus.none).isBusyElsewhere, isFalse);
      final busy = _snap(
        MyMatchmakingStatus.none,
        elsewhere: SearchingElsewhere(
          teamId: 't2',
          teamName: 'Outro',
          expiresAt: _now,
        ),
      );
      expect(busy.isBusyElsewhere, isTrue);
    });

    test('a fila padrão é vazia e imutável por valor', () {
      final s = _snap(MyMatchmakingStatus.none);
      expect(s.queue, isEmpty);
      expect(s.searching, isNull);
      expect(s.blockingSearch, isNull);
    });

    test('igualdade por valor, inclusive a fila inteira', () {
      final q = [
        const QueueEntry(
          position: 1,
          userId: 'a',
          displayName: 'Ana',
          isMe: false,
        ),
        const QueueEntry(
          position: 2,
          userId: 'u1',
          displayName: 'Eu',
          isMe: true,
        ),
      ];
      expect(
        _snap(MyMatchmakingStatus.queued, queue: q),
        _snap(MyMatchmakingStatus.queued, queue: List.of(q)),
      );
      expect(
        _snap(MyMatchmakingStatus.queued, queue: q),
        isNot(_snap(MyMatchmakingStatus.queued, queue: [q.first])),
      );
    });

    test('o relógio do servidor faz parte da identidade', () {
      final a = _snap(MyMatchmakingStatus.none);
      final b = MyMatchmakingSnapshot(
        userId: 'u1',
        teamId: 't1',
        myStatus: MyMatchmakingStatus.none,
        serverNow: _now.add(const Duration(seconds: 1)),
      );
      expect(a, isNot(b));
    });
  });

  group('entidades de apoio', () {
    test(
      'MySearching, BlockingSearch e QueueEntry comparam todos os campos',
      () {
        final s1 = MySearching(
          sessionId: 's',
          startedAt: _now,
          expiresAt: _now,
          gameMode: GameMode.weekendLeague,
          fcSquadName: 'Time A',
        );
        final s2 = MySearching(
          sessionId: 's',
          startedAt: _now,
          expiresAt: _now,
          gameMode: GameMode.weekendLeague,
          fcSquadName: 'Time A',
        );
        final s3 = MySearching(
          sessionId: 's',
          startedAt: _now,
          expiresAt: _now,
          gameMode: GameMode.divisionRivals,
          fcSquadName: 'Time A',
        );
        expect(s1, s2);
        expect(s1, isNot(s3));

        final b = BlockingSearch(
          userId: 'x',
          displayName: 'Rival',
          expiresAt: _now,
        );
        expect(
          b,
          BlockingSearch(userId: 'x', displayName: 'Rival', expiresAt: _now),
        );
        expect(
          b,
          isNot(
            BlockingSearch(userId: 'x', displayName: 'Outro', expiresAt: _now),
          ),
        );

        const q = QueueEntry(
          position: 1,
          userId: 'a',
          displayName: 'Ana',
          isMe: false,
        );
        expect(
          q,
          isNot(
            const QueueEntry(
              position: 1,
              userId: 'a',
              displayName: 'Ana',
              isMe: true,
            ),
          ),
        );
      },
    );
  });
}
