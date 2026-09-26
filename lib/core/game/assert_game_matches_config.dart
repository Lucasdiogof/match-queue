import 'package:fifa_queue/core/config/app_config.dart';
import 'package:fifa_queue/core/game/game_config.dart';
import 'package:fifa_queue/core/game/supabase_project_ref.dart';

/// Trava cross-flavor: builda pro jogo X mas com o env/dart-define de outro
/// jogo (ex.: comando de build esqueceu de trocar o `--dart-define-from-file`
/// pro env do flavor certo) nunca deve conseguir seguir em frente -- falha
/// aqui, alto e cedo, em vez de inicializar contra o Supabase/backend do
/// jogo errado silenciosamente.
///
/// Três checagens independentes, qualquer uma pode pegar o problema:
/// 1. `APP_URL_SCHEME` bate com o que o jogo espera;
/// 2. `APP_BACKEND_GAME` (o env se autodeclarando "eu sou o backend de qual
///    jogo") bate com o jogo resolvido;
/// 3. se o jogo já tem um Supabase próprio conhecido, o ref extraído de
///    `SUPABASE_URL` bate com o esperado (pega o caso "scheme e
///    backend-game corretos, mas SUPABASE_URL ainda aponta pro projeto
///    errado").
void assertGameMatchesConfig(GameConfig gameConfig, AppConfig appConfig) {
  if (appConfig.appUrlScheme != gameConfig.expectedUrlScheme) {
    throw StateError(
      'Config incompatível: build resolveu o jogo "${gameConfig.key.key}" '
      '(esperava APP_URL_SCHEME="${gameConfig.expectedUrlScheme}") mas o '
      'env/dart-define carregado tem APP_URL_SCHEME='
      '"${appConfig.appUrlScheme}". Provavelmente o comando de build usou '
      'o env/dart-define de outro flavor -- corrija antes de continuar.',
    );
  }

  if (appConfig.backendGame != gameConfig.key.key) {
    throw StateError(
      'Config incompatível: build resolveu o jogo "${gameConfig.key.key}" '
      'mas o env carregado se autodeclara backend do jogo '
      '"${appConfig.backendGame}" (APP_BACKEND_GAME). Provavelmente o '
      'comando de build usou o env/dart-define de outro flavor -- corrija '
      'antes de continuar.',
    );
  }

  final expectedRef = gameConfig.expectedSupabaseProjectRef;
  if (expectedRef != null) {
    final actualRef = supabaseProjectRefFrom(appConfig.supabaseUrl);
    if (actualRef != null && actualRef != expectedRef) {
      throw StateError(
        'Config incompatível: build resolveu o jogo "${gameConfig.key.key}" '
        '(esperava o projeto Supabase "$expectedRef") mas SUPABASE_URL '
        'aponta pro projeto "$actualRef". Provavelmente o env carregado '
        'pertence a outro flavor -- corrija antes de continuar.',
      );
    }
  }
}
