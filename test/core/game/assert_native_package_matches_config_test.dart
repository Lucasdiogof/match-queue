import 'package:fifa_queue/core/game/assert_native_package_matches_config.dart';
import 'package:fifa_queue/games/ea_fc/ea_fc_game_config.dart';
import 'package:fifa_queue/games/efootball/efootball_game_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app nativo do EA FC com jogo resolvido EA FC passa', () {
    expect(
      () => assertNativePackageMatchesGame(
        eaFcGameConfig,
        'com.lucasdiogof.fifaqueue',
      ),
      returnsNormally,
    );
  });

  test('app nativo do eFootball com jogo resolvido eFootball passa', () {
    expect(
      () => assertNativePackageMatchesGame(
        efootballGameConfig,
        'com.lucasdiogof.matchqueue.efootball',
      ),
      returnsNormally,
    );
  });

  test(
    'app nativo do eFootball mas jogo resolvido EA FC falha alto e cedo',
    () {
      expect(
        () => assertNativePackageMatchesGame(
          eaFcGameConfig,
          'com.lucasdiogof.matchqueue.efootball',
        ),
        throwsStateError,
      );
    },
  );

  test(
    'app nativo do EA FC mas jogo resolvido eFootball falha alto e cedo',
    () {
      expect(
        () => assertNativePackageMatchesGame(
          efootballGameConfig,
          'com.lucasdiogof.fifaqueue',
        ),
        throwsStateError,
      );
    },
  );
}
