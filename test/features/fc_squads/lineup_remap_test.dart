import 'package:fifa_queue/features/fc_squads/domain/entities/formation.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/fc_squads/domain/lineup_remap.dart';
import 'package:flutter_test/flutter_test.dart';

PlayerCard _card(String name, String primary, [List<String> alt = const []]) =>
    PlayerCard(
      id: name,
      provider: 'TEST',
      playerName: name,
      rating: 80,
      primaryPosition: primary,
      alternativePositions: alt,
    );

FormationSlot _slot(String code, String position, double x, double y) =>
    FormationSlot(
      slotCode: code,
      positionCode: position,
      x: x,
      y: y,
      sortOrder: 0,
    );

RemapEntry _entry(
  String slotCode,
  String positionCode,
  PlayerCard card, {
  double x = 0.5,
  double y = 0.5,
}) => RemapEntry(
  slotCode: slotCode,
  card: card,
  positionCode: positionCode,
  x: x,
  y: y,
);

void main() {
  group('remapLineup', () {
    test('mantem o jogador no mesmo slot quando ele sobrevive', () {
      final gk = _card('gk', 'GK');
      final result = remapLineup(
        current: <RemapEntry>[_entry('GK', 'GK', gk, x: 0.5, y: 0.05)],
        target: <FormationSlot>[_slot('GK', 'GK', 0.5, 0.05)],
      );
      expect(result.assigned['GK'], gk);
      expect(result.dropped, isEmpty);
    });

    test('reaproveita pela mesma posicao quando o slot mudou de nome', () {
      final cb = _card('cb', 'CB');
      final result = remapLineup(
        current: <RemapEntry>[_entry('CB1', 'CB', cb)],
        target: <FormationSlot>[_slot('LCB', 'CB', 0.35, 0.2)],
      );
      expect(result.assigned['LCB'], cb);
      expect(result.dropped, isEmpty);
    });

    test('usa alternativa real quando a posicao exata sumiu', () {
      final wing = _card('wing', 'LM', <String>['LW']);
      final result = remapLineup(
        current: <RemapEntry>[_entry('LM', 'LM', wing)],
        target: <FormationSlot>[_slot('LW', 'LW', 0.2, 0.8)],
      );
      expect(result.assigned['LW'], wing);
    });

    test('NUNCA encaixa em posicao incompativel, mesmo com slot livre', () {
      // Era exatamente o que a passada antiga do servidor fazia: se sobrou
      // slot perto, escalava o atacante de lateral.
      final st = _card('st', 'ST', <String>['CF']);
      final result = remapLineup(
        current: <RemapEntry>[_entry('ST', 'ST', st, x: 0.5, y: 0.9)],
        target: <FormationSlot>[_slot('LB', 'LB', 0.5, 0.88)],
      );
      expect(result.assigned, isEmpty);
      expect(result.dropped, <PlayerCard>[st]);
    });

    test('quem nao cabe sai da escalacao, sem banco escondido', () {
      final a = _card('a', 'CB');
      final b = _card('b', 'CB');
      final result = remapLineup(
        current: <RemapEntry>[_entry('CB1', 'CB', a), _entry('CB2', 'CB', b)],
        target: <FormationSlot>[_slot('CB', 'CB', 0.5, 0.2)],
      );
      expect(result.assigned.length, 1);
      expect(result.dropped.length, 1);
    });

    test('nunca duplica: um slot recebe um jogador so', () {
      final a = _card('a', 'CM');
      final b = _card('b', 'CM');
      final result = remapLineup(
        current: <RemapEntry>[_entry('CM1', 'CM', a), _entry('CM2', 'CM', b)],
        target: <FormationSlot>[
          _slot('CM1', 'CM', 0.4, 0.5),
          _slot('CM2', 'CM', 0.6, 0.5),
        ],
      );
      expect(result.assigned.values.toSet().length, 2);
      expect(result.assigned.length, 2);
      expect(result.dropped, isEmpty);
    });

    test('prefere o mesmo lado antes da distancia pura', () {
      // O slot direito esta um pouco mais perto em linha reta, mas o jogador
      // vinha da esquerda -- coerencia de lado ganha.
      final left = _card('left', 'LM', <String>['LB']);
      final result = remapLineup(
        current: <RemapEntry>[_entry('LM', 'LM', left, x: 0.1, y: 0.5)],
        target: <FormationSlot>[
          _slot('RB', 'LB', 0.12, 0.5),
          _slot('LB', 'LB', 0.15, 0.5),
        ],
      );
      expect(result.assigned.containsKey('LB'), isTrue);
      expect(result.assigned.containsKey('RB'), isFalse);
    });

    test('goleiro nao vira jogador de linha quando o GK some', () {
      final gk = _card('gk', 'GK');
      final result = remapLineup(
        current: <RemapEntry>[_entry('GK', 'GK', gk)],
        target: <FormationSlot>[_slot('CB', 'CB', 0.5, 0.2)],
      );
      expect(result.dropped, <PlayerCard>[gk]);
    });

    test('escalacao vazia continua vazia', () {
      final result = remapLineup(
        current: const <RemapEntry>[],
        target: <FormationSlot>[_slot('GK', 'GK', 0.5, 0.05)],
      );
      expect(result.assigned, isEmpty);
      expect(result.dropped, isEmpty);
    });
  });
}
