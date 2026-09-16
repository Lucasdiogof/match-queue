import 'package:shared_preferences/shared_preferences.dart';

/// Chaveado por Conta FC, nao por login: cada Conta pode estar em times
/// diferentes, entao cada uma lembra o proprio ultimo time selecionado.
class SelectedTeamStore {
  const SelectedTeamStore(this._preferences);

  final SharedPreferences _preferences;

  static const String _keyPrefix = 'teams.last_selected.';

  String _keyFor(String profileId) => '$_keyPrefix$profileId';

  String? read(String profileId) {
    final value = _preferences.getString(_keyFor(profileId));
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<void> write(String profileId, String? teamId) async {
    final key = _keyFor(profileId);
    if (teamId == null || teamId.isEmpty) {
      await _preferences.remove(key);
    } else {
      await _preferences.setString(key, teamId);
    }
  }
}
