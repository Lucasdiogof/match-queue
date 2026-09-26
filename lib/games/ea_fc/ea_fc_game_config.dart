import 'package:fifa_queue/core/game/game_capabilities.dart';
import 'package:fifa_queue/core/game/game_config.dart';
import 'package:fifa_queue/core/game/game_flavor_key.dart';
import 'package:fifa_queue/core/game/game_mode_descriptor.dart';

/// Config do flavor EA SPORTS FC -- hoje o único jogo real do Match Queue.
/// Nada aqui muda o comportamento atual do app; é só a fundação para o
/// próximo flavor (eFootball) não precisar redesenhar isto.
const GameConfig eaFcGameConfig = GameConfig(
  key: GameFlavorKey.eaFc,
  appName: 'Match Queue',
  gameName: 'EA SPORTS FC',
  gameVersionName: 'FC 27',
  capabilities: GameCapabilities(
    teams: true,
    matchmaking: true,
    history: true,
    squads: true,
    cards: true,
    market: true,
    playStyles: true,
    chemistry: true,
    evolutions: true,
  ),
  gameModes: <GameModeDescriptor>[
    GameModeDescriptor(
      code: 'WEEKEND_LEAGUE',
      name: 'Champions',
      isRanked: true,
    ),
    GameModeDescriptor(code: 'DIVISION_RIVALS', name: 'Rivals', isRanked: true),
  ],
);
