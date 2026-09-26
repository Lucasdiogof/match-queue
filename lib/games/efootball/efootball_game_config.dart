import 'package:fifa_queue/core/game/game_capabilities.dart';
import 'package:fifa_queue/core/game/game_config.dart';
import 'package:fifa_queue/core/game/game_flavor_key.dart';
import 'package:fifa_queue/core/game/game_mode_descriptor.dart';

/// Config do flavor eFootball. Só o core compartilhado (times, matchmaking,
/// histórico) está habilitado -- nada de catálogo/cartas/química/PlayStyles/
/// evoluções/Mercado, que são conteúdo específico do EA FC ainda não
/// auditado/portado para este jogo. `gameModes` fica vazio de propósito: os
/// modos competitivos reais do eFootball ainda não foram pesquisados: nomes
/// fictícios aqui só pra "preencher" o tipo seriam pior que a lista vazia.
const GameConfig efootballGameConfig = GameConfig(
  key: GameFlavorKey.efootball,
  appName: 'Match Queue',
  gameName: 'eFootball',
  gameVersionName: '',
  capabilities: GameCapabilities(
    teams: true,
    matchmaking: true,
    history: true,
    squads: false,
    cards: false,
    market: false,
    playStyles: false,
    chemistry: false,
    evolutions: false,
    controlsGuide: false,
  ),
  gameModes: <GameModeDescriptor>[],
  expectedUrlScheme: 'com.lucasdiogof.matchqueue.efootball',
  expectedPackageIdentifiers: <String>{'com.lucasdiogof.matchqueue.efootball'},
  // Sem Supabase próprio ainda -- fica pendente até o projeto existir (ver
  // docs/game_flavors.md).
  expectedSupabaseProjectRef: null,
);
