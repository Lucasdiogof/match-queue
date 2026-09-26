import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/config/app_environment.dart';

class AppConfig extends Equatable {
  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.appLinkHost,
    required this.appUrlScheme,
    required this.backendGame,
    required this.firebaseEnabled,
    required this.verboseLogging,
  });

  static const String _publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const String _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // Default = applicationId/bundle id do flavor EA FC. Builds existentes
  // (sem APP_URL_SCHEME no env) continuam resolvendo pro mesmo scheme de
  // sempre; um novo flavor de jogo define o dele no próprio env/*.json.
  static const String _defaultUrlScheme = 'com.lucasdiogof.fifaqueue';

  // Idem, mas para de qual jogo o env/Supabase carregado diz que É --
  // ausente (env antigo, sem essa chave) = EA FC, o único que existia até
  // esta fundação.
  static const String _defaultBackendGame = 'ea_fc';

  static AppConfig fromEnvironment() {
    final environment = AppEnvironment.resolve();
    return AppConfig(
      environment: environment,
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabasePublishableKey: _publishableKey.isNotEmpty
          ? _publishableKey
          : _anonKey,
      appLinkHost: const String.fromEnvironment('APP_LINK_HOST'),
      appUrlScheme: const String.fromEnvironment(
        'APP_URL_SCHEME',
        defaultValue: _defaultUrlScheme,
      ),
      backendGame: const String.fromEnvironment(
        'APP_BACKEND_GAME',
        defaultValue: _defaultBackendGame,
      ),
      firebaseEnabled: const bool.fromEnvironment('FIREBASE_ENABLED'),
      verboseLogging: const bool.fromEnvironment(
        'VERBOSE_LOGGING',
        defaultValue: true,
      ),
    );
  }

  final AppEnvironment environment;
  final String supabaseUrl;
  final String supabasePublishableKey;
  final String appLinkHost;
  final String appUrlScheme;

  /// Qual jogo o env carregado DIZ que é (`APP_BACKEND_GAME`) -- não é o
  /// jogo resolvido pelo `APP_GAME`/`GameConfig`, é o env do backend em si
  /// se autodeclarando. Serve só pro guard `assertGameMatchesConfig`
  /// comparar os dois; nada mais lê este campo diretamente.
  final String backendGame;

  final bool firebaseEnabled;
  final bool verboseLogging;

  bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  bool get hasAppLinkHost => appLinkHost.isNotEmpty;

  List<String> get missingRequiredKeys => <String>[
    if (supabaseUrl.isEmpty) 'SUPABASE_URL',
    if (supabasePublishableKey.isEmpty) 'SUPABASE_PUBLISHABLE_KEY',
  ];

  bool get isUsable => hasSupabase;

  @override
  List<Object?> get props => <Object?>[
    environment,
    supabaseUrl,
    supabasePublishableKey,
    appLinkHost,
    appUrlScheme,
    backendGame,
    firebaseEnabled,
    verboseLogging,
  ];
}
