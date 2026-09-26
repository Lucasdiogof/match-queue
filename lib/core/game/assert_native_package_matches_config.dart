import 'package:fifa_queue/core/game/game_config.dart';

/// Trava cross-flavor mais forte que `assertGameMatchesConfig`: compara o
/// applicationId/bundle id do APP NATIVO de verdade (lido em runtime via
/// `package_info_plus`, não um dart-define) contra o que `GameConfig`
/// espera pro jogo resolvido. Um dart-define errado pode mentir; o
/// package/bundle instalado não -- ele é decidido no build nativo
/// (productFlavor/xcconfig), fora do alcance de qualquer `--dart-define`.
///
/// Só faz sentido em Android/iOS -- não chamar isso no Web (sem
/// applicationId/bundle id nativo) nem desktop.
void assertNativePackageMatchesGame(
  GameConfig gameConfig,
  String nativePackageName,
) {
  if (!gameConfig.expectedPackageIdentifiers.contains(nativePackageName)) {
    throw StateError(
      'Config incompatível: o app nativo instalado tem package/bundle id '
      '"$nativePackageName", mas o jogo resolvido via APP_GAME '
      '("${gameConfig.key.key}") esperava um destes: '
      '${gameConfig.expectedPackageIdentifiers.join(", ")}. Provavelmente '
      'este é o build nativo de um flavor rodando com o APP_GAME de outro '
      '-- corrija o --flavor ou o --dart-define=APP_GAME antes de '
      'continuar.',
    );
  }
}
