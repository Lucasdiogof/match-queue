import 'package:fifa_queue/core/game/game_flavor_key.dart';
import 'package:fifa_queue/core/game/game_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registry só conhece jogos com flavor real', () {
    expect(gameRegistry.keys, <GameFlavorKey>{
      GameFlavorKey.eaFc,
      GameFlavorKey.efootball,
    });
  });

  test('jogos sem flavor real não aparecem no registry', () {
    expect(gameRegistry.containsKey(GameFlavorKey.ufl), isFalse);
    expect(gameRegistry.containsKey(GameFlavorKey.goals), isFalse);
  });
}
