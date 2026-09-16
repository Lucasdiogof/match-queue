import 'package:shared_preferences/shared_preferences.dart';

/// Lembra, localmente, ate quando uma Conta+Time+Modo ainda esta em
/// cooldown pra buscar de novo depois de cancelar -- sobrevive a
/// MatchmakingCubit ser recriado (trocar de conta, time ou modo descarta o
/// cubit e o cooldownEndsAt que ele guardava so na memoria junto). Chaveado
/// pelos tres porque cada combinacao tem sua propria fila/cooldown.
///
/// Preferencia do dispositivo, nao fonte de verdade -- o servidor so aplica
/// cooldown de verdade depois de uma partida encontrada (game_matches),
/// nunca depois de um cancelamento. Esse aqui e so pra nao deixar a UI
/// liberar o botao "Buscar partida" na cara dura assim que o cubit antigo
/// morre, mesmo tendo acabado de cancelar.
class SearchCooldownStore {
  const SearchCooldownStore(this._preferences);

  final SharedPreferences _preferences;

  String _key(String fcAccountId, String teamId, String modeKey) =>
      'matchmaking.cooldown.$fcAccountId.$teamId.$modeKey';

  DateTime? read(String fcAccountId, String teamId, String modeKey) {
    final raw = _preferences.getString(_key(fcAccountId, teamId, modeKey));
    if (raw == null) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  Future<void> write(
    String fcAccountId,
    String teamId,
    String modeKey,
    DateTime endsAt,
  ) => _preferences.setString(
    _key(fcAccountId, teamId, modeKey),
    endsAt.toIso8601String(),
  );
}
