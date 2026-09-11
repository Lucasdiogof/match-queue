import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/fc_squads/presentation/cubit/player_picker_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

PlayerCard _card(String name, String primary, List<String> alternatives) =>
    PlayerCard(
      id: name,
      provider: 'TEST',
      playerName: name,
      rating: 80,
      primaryPosition: primary,
      alternativePositions: alternatives,
    );

void main() {
  group('eligibilityTier', () {
    test('posicao principal vem primeiro', () {
      expect(eligibilityTier(_card('a', 'LB', const <String>[]), 'LB'), 0);
    });

    test('alternativa declarada e elegivel', () {
      expect(eligibilityTier(_card('a', 'CB', const <String>['LB']), 'LB'), 1);
    });

    test('sem relacao declarada NAO e elegivel, mesmo sendo defensor', () {
      // A regra e posicao principal + alternativas reais da carta. Nada de
      // "LB aceita qualquer defensor" -- um zagueiro central sem LB entre as
      // alternativas nao joga ali.
      expect(eligibilityTier(_card('a', 'CB', const <String>[]), 'LB'), 2);
    });

    test('atacante nunca e sugestao de lateral', () {
      expect(eligibilityTier(_card('a', 'ST', const <String>['CF']), 'LB'), 2);
    });

    test('goleiro so e elegivel em GK', () {
      final gk = _card('a', 'GK', const <String>[]);
      expect(eligibilityTier(gk, 'GK'), 0);
      expect(eligibilityTier(gk, 'CB'), 2);
    });

    test('jogador de linha nao entra no gol', () {
      expect(eligibilityTier(_card('a', 'CB', const <String>[]), 'GK'), 2);
    });
  });
}
