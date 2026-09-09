import 'package:fifa_queue/features/history/data/models/match_history_model.dart';
import 'package:fifa_queue/features/history/domain/entities/game_match_status.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _row({
  Object? matchStatus,
  Object? result,
  Object? goalsFor,
  Object? goalsAgainst,
  Object? gameMode = 'DIVISION_RIVALS',
  Object? accountName = 'Lucksrei',
}) => <String, dynamic>{
  'session_id': 's1',
  'user_id': 'u1',
  'display_name': 'Lucas',
  'status': 'MATCH_FOUND',
  'started_at': '2026-09-09T18:00:00Z',
  'finished_at': '2026-09-09T18:02:00Z',
  'duration_seconds': 120,
  'configured_duration_seconds': 300,
  'game_mode': gameMode,
  'fc_account_name': accountName,
  'match_status': matchStatus,
  'result': result,
  'goals_for': goalsFor,
  'goals_against': goalsAgainst,
};

void main() {
  group('resultado ausente nunca vira derrota', () {
    test(
      'partida abandonada sem resultado fica marcada como nao informada',
      () {
        final entry = MatchHistoryModel.entryFromJson(
          _row(matchStatus: 'ABANDONED'),
        );

        expect(entry.hasMatch, isTrue);
        expect(entry.result, isNull);
        expect(entry.isResultUnreported, isTrue);
        expect(entry.matchStatus, GameMatchStatus.abandoned);
      },
    );

    test('busca que nunca virou partida nao e resultado nao informado', () {
      final entry = MatchHistoryModel.entryFromJson(_row());

      expect(entry.hasMatch, isFalse);
      expect(
        entry.isResultUnreported,
        isFalse,
        reason: 'sem partida nao ha resultado a informar',
      );
    });

    test('vitoria sem placar conta como resultado e nao fabrica gols', () {
      final entry = MatchHistoryModel.entryFromJson(
        _row(matchStatus: 'FINISHED', result: 'WIN'),
      );

      expect(entry.isResultUnreported, isFalse);
      expect(entry.hasScore, isFalse);
      expect(entry.goalsFor, isNull);
      expect(entry.goalsAgainst, isNull);
    });

    test('placar zero a zero continua sendo placar informado', () {
      final entry = MatchHistoryModel.entryFromJson(
        _row(
          matchStatus: 'FINISHED',
          result: 'LOSS',
          goalsFor: 0,
          goalsAgainst: 0,
        ),
      );

      expect(
        entry.hasScore,
        isTrue,
        reason: '0 e um placar, nao ausencia de placar',
      );
    });
  });

  group('contexto da partida', () {
    test('modalidade desconhecida vira null em vez de cair num padrao', () {
      final entry = MatchHistoryModel.entryFromJson(
        _row(gameMode: 'SQUAD_BATTLES'),
      );

      expect(
        entry.gameMode,
        isNull,
        reason: 'GameMode.fromKey cairia em divisionRivals e mentiria a tela',
      );
    });

    test('conta apagada nao derruba a linha do historico', () {
      final entry = MatchHistoryModel.entryFromJson(_row(accountName: null));

      expect(entry.fcAccountName, isNull);
      expect(entry.sessionId, 's1');
      expect(entry.gameMode, GameMode.divisionRivals);
    });
  });
}
