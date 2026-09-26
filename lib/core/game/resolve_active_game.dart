import 'package:fifa_queue/core/game/game_config.dart';
import 'package:fifa_queue/core/game/game_flavor_key.dart';
import 'package:fifa_queue/core/game/game_registry.dart';

const String _appGameEnv = String.fromEnvironment('APP_GAME');

/// Resolve o jogo ativo desta build a partir de `--dart-define=APP_GAME=...`.
///
/// Ausente = EA FC (todo build existente hoje, sem esse define, continua
/// funcionando sem mudança nenhuma). Presente mas desconhecido ou ainda sem
/// flavor real = falha alto e cedo -- nunca cai silenciosamente para EA FC,
/// pra não arriscar um build de outro jogo servir dado/UI do jogo errado.
GameConfig resolveActiveGame([String envValue = _appGameEnv]) {
  if (envValue.isEmpty) {
    return gameRegistry[GameFlavorKey.eaFc]!;
  }

  final key = GameFlavorKey.tryFromKey(envValue);
  final config = key == null ? null : gameRegistry[key];
  if (config == null) {
    throw StateError(
      'APP_GAME="$envValue" não corresponde a nenhum jogo com flavor '
      'configurado no gameRegistry.',
    );
  }
  return config;
}
