import 'package:shared_preferences/shared_preferences.dart';

class SelectedProfileStore {
  const SelectedProfileStore(this._preferences);

  final SharedPreferences _preferences;

  static const String _keyPrefix = 'profiles.last_selected.';

  /// Chave usada antes do Perfil se chamar Perfil (era "Conta FC"). Quem ja
  /// tinha o app instalado carrega a selecao por aqui uma unica vez -- sem
  /// isto, a atualizacao cairia no fallback de "primeiro Perfil da lista" e
  /// trocaria o Perfil ativo de quem tem mais de um, do nada.
  static const String _legacyKeyPrefix = 'fc_accounts.last_selected.';

  String _keyFor(String userId) => '$_keyPrefix$userId';

  String _legacyKeyFor(String userId) => '$_legacyKeyPrefix$userId';

  String? read(String userId) {
    final value = _preferences.getString(_keyFor(userId));
    if (value != null && value.isNotEmpty) {
      return value;
    }
    final legacy = _preferences.getString(_legacyKeyFor(userId));
    return (legacy == null || legacy.isEmpty) ? null : legacy;
  }

  Future<void> write(String userId, String? profileId) async {
    final key = _keyFor(userId);
    if (profileId == null || profileId.isEmpty) {
      await _preferences.remove(key);
    } else {
      await _preferences.setString(key, profileId);
    }
    // A chave antiga so sai depois que a nova ja foi gravada (ou limpa):
    // se o app morrer no meio, o pior caso e ler a antiga de novo, nunca
    // ficar sem nenhuma.
    await _preferences.remove(_legacyKeyFor(userId));
  }
}
