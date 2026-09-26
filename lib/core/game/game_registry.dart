import 'package:fifa_queue/core/game/game_config.dart';
import 'package:fifa_queue/core/game/game_flavor_key.dart';
import 'package:fifa_queue/games/ea_fc/ea_fc_game_config.dart';

/// Todos os jogos que já têm uma build real. UFL/eFootball/GOALS só entram
/// aqui quando o flavor deles for de fato criado (novo Supabase, novo
/// build) -- até lá, `GameFlavorKey` pode conhecer a chave, mas o registry
/// não resolve config nenhuma para elas.
final Map<GameFlavorKey, GameConfig> gameRegistry = <GameFlavorKey, GameConfig>{
  GameFlavorKey.eaFc: eaFcGameConfig,
};
