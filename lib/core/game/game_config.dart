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
    required this.expectedUrlScheme,
    required this.expectedPackageIdentifiers,
    this.expectedSupabaseProjectRef,
  });

  final GameFlavorKey key;
  final String appName;
  final String gameName;
  final String gameVersionName;
  final GameCapabilities capabilities;
  final List<GameModeDescriptor> gameModes;

  /// O `APP_URL_SCHEME`/`AUTH_CALLBACK_SCHEME` que ESTE jogo deveria ter
  /// (mesmo valor configurado nos productFlavors/xcconfig nativos). Serve
  /// só para o guard em `assertGameMatchesConfig` -- nunca para escolher o
  /// scheme em si, que continua vindo do `AppConfig`/env de cada flavor.
  final String expectedUrlScheme;

  /// applicationId (Android) / bundle id (iOS) do app nativo que builda
  /// este jogo -- hoje o mesmo valor nos dois sistemas, mas fica como
  /// conjunto para o dia em que divergirem. Usado só pelo guard
  /// `assertNativePackageMatchesGame` (mobile); não se aplica a Web.
  final Set<String> expectedPackageIdentifiers;

  /// Ref (subdomínio) do projeto Supabase esperado pra este jogo, extraído
  /// de `https://<ref>.supabase.co`. Nulo = ainda não temos projeto próprio
  /// pra derivar (caso do eFootball, até o Supabase dele existir) -- o
  /// guard correspondente simplesmente não roda enquanto for nulo.
  final String? expectedSupabaseProjectRef;

  @override
  List<Object?> get props => <Object?>[
    key,
    appName,
    gameName,
    gameVersionName,
    capabilities,
    gameModes,
    expectedUrlScheme,
    expectedPackageIdentifiers,
    expectedSupabaseProjectRef,
  ];
}
