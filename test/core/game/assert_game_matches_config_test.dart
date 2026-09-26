import 'package:fifa_queue/core/config/app_config.dart';
import 'package:fifa_queue/core/config/app_environment.dart';
import 'package:fifa_queue/core/game/assert_game_matches_config.dart';
import 'package:fifa_queue/games/ea_fc/ea_fc_game_config.dart';
import 'package:fifa_queue/games/efootball/efootball_game_config.dart';
import 'package:flutter_test/flutter_test.dart';

// Domínio fora de *.supabase.co de propósito: supabaseProjectRefFrom
// retorna null pra ele, então a checagem 3 (ref) não entra no caminho a
// menos que o teste queira exercitar exatamente ela.
const String _nonSupabaseUrl = 'https://example.test';

AppConfig _config({
  required String scheme,
  required String backendGame,
  String supabaseUrl = _nonSupabaseUrl,
}) => AppConfig(
  environment: AppEnvironment.development,
  supabaseUrl: supabaseUrl,
  supabasePublishableKey: 'key',
  appLinkHost: '',
  appUrlScheme: scheme,
  backendGame: backendGame,
  firebaseEnabled: false,
  verboseLogging: false,
);

void main() {
  test('EA FC com o próprio scheme e backend passa no guard', () {
    expect(
      () => assertGameMatchesConfig(
        eaFcGameConfig,
        _config(scheme: 'com.lucasdiogof.fifaqueue', backendGame: 'ea_fc'),
      ),
      returnsNormally,
    );
  });

  test('eFootball com o próprio scheme e backend passa no guard', () {
    expect(
      () => assertGameMatchesConfig(
        efootballGameConfig,
        _config(
          scheme: 'com.lucasdiogof.matchqueue.efootball',
          backendGame: 'efootball',
        ),
      ),
      returnsNormally,
    );
  });

  test('eFootball com scheme do EA FC falha alto e cedo', () {
    expect(
      () => assertGameMatchesConfig(
        efootballGameConfig,
        _config(scheme: 'com.lucasdiogof.fifaqueue', backendGame: 'efootball'),
      ),
      throwsStateError,
    );
  });

  test('EA FC com scheme do eFootball falha alto e cedo', () {
    expect(
      () => assertGameMatchesConfig(
        eaFcGameConfig,
        _config(
          scheme: 'com.lucasdiogof.matchqueue.efootball',
          backendGame: 'ea_fc',
        ),
      ),
      throwsStateError,
    );
  });

  test(
    'scheme e APP_GAME corretos mas APP_BACKEND_GAME de outro jogo falha',
    () {
      // O cenário que o guard antigo (só scheme) deixava passar.
      expect(
        () => assertGameMatchesConfig(
          efootballGameConfig,
          _config(
            scheme: 'com.lucasdiogof.matchqueue.efootball',
            backendGame: 'ea_fc',
          ),
        ),
        throwsStateError,
      );
    },
  );

  test(
    'scheme e backend corretos mas SUPABASE_URL do projeto errado falha',
    () {
      expect(
        () => assertGameMatchesConfig(
          eaFcGameConfig,
          _config(
            scheme: 'com.lucasdiogof.fifaqueue',
            backendGame: 'ea_fc',
            supabaseUrl: 'https://outro-projeto-qualquer.supabase.co',
          ),
        ),
        throwsStateError,
      );
    },
  );

  test(
    'SUPABASE_URL do projeto certo do EA FC passa a checagem de ref',
    () {
      expect(
        () => assertGameMatchesConfig(
          eaFcGameConfig,
          _config(
            scheme: 'com.lucasdiogof.fifaqueue',
            backendGame: 'ea_fc',
            supabaseUrl: 'https://lteujeclnhmurcewurkg.supabase.co',
          ),
        ),
        returnsNormally,
      );
    },
  );

  test(
    'eFootball ainda não tem project ref conhecido -- checagem 3 não roda',
    () {
      expect(
        () => assertGameMatchesConfig(
          efootballGameConfig,
          _config(
            scheme: 'com.lucasdiogof.matchqueue.efootball',
            backendGame: 'efootball',
            supabaseUrl: 'https://qualquer-coisa.supabase.co',
          ),
        ),
        returnsNormally,
      );
    },
  );
}
