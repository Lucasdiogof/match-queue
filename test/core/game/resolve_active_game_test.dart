import 'package:fifa_queue/core/game/game_flavor_key.dart';
import 'package:fifa_queue/core/game/resolve_active_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveActiveGame', () {
    test(
      'sem APP_GAME resolve para EA FC (compatibilidade com builds atuais)',
      () {
        final game = resolveActiveGame('');

        expect(game.key, GameFlavorKey.eaFc);
      },
    );

    test('APP_GAME=ea_fc resolve para EA FC', () {
      final game = resolveActiveGame('ea_fc');

      expect(game.key, GameFlavorKey.eaFc);
    });

    test('APP_GAME=efootball resolve para eFootball', () {
      final game = resolveActiveGame('efootball');

      expect(game.key, GameFlavorKey.efootball);
    });

    test(
      'APP_GAME desconhecido falha em vez de cair silenciosamente pra EA FC',
      () {
        expect(() => resolveActiveGame('not_a_real_game'), throwsStateError);
      },
    );

    test('APP_GAME de jogo conhecido mas sem flavor real ainda falha', () {
      expect(() => resolveActiveGame('ufl'), throwsStateError);
      expect(() => resolveActiveGame('goals'), throwsStateError);
    });
  });
}
