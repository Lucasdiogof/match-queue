import 'package:fifa_queue/games/ea_fc/ea_fc_game_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EA FC tem todas as capabilities existentes hoje habilitadas', () {
    final capabilities = eaFcGameConfig.capabilities;

    expect(capabilities.teams, isTrue);
    expect(capabilities.matchmaking, isTrue);
    expect(capabilities.history, isTrue);
    expect(capabilities.squads, isTrue);
    expect(capabilities.cards, isTrue);
    expect(capabilities.market, isTrue);
    expect(capabilities.playStyles, isTrue);
    expect(capabilities.chemistry, isTrue);
    expect(capabilities.evolutions, isTrue);
  });

  test('EA FC declara Champions e Rivals como game modes', () {
    final codes = eaFcGameConfig.gameModes.map((mode) => mode.code);

    expect(codes, containsAll(<String>['WEEKEND_LEAGUE', 'DIVISION_RIVALS']));
  });
}
