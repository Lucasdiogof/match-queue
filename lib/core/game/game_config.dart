import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/game/game_capabilities.dart';
import 'package:fifa_queue/core/game/game_flavor_key.dart';
import 'package:fifa_queue/core/game/game_mode_descriptor.dart';

/// Configuração do jogo ativo nesta build do Match Queue. Backend
/// (Supabase URL/key) continua vindo do `AppConfig`/env -- cada flavor de
/// jogo terá seu próprio conjunto de variáveis de ambiente quando existir,
/// não credenciais embutidas aqui.
class GameConfig extends Equatable {
  const GameConfig({
    required this.key,
    required this.appName,
    required this.gameName,
    required this.gameVersionName,
    required this.capabilities,
    required this.gameModes,
  });

  final GameFlavorKey key;
  final String appName;
  final String gameName;
  final String gameVersionName;
  final GameCapabilities capabilities;
  final List<GameModeDescriptor> gameModes;

  @override
  List<Object?> get props => <Object?>[
    key,
    appName,
    gameName,
    gameVersionName,
    capabilities,
    gameModes,
  ];
}
