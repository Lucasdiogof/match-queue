import 'package:shared_preferences/shared_preferences.dart';

class SelectedTeamStore {
  const SelectedTeamStore(this._preferences);

  final SharedPreferences _preferences;

  static const String _keyPrefix = 'teams.last_selected.';

  String _keyFor(String userId) => '$_keyPrefix$userId';

  String? read(String userId) {
    final value = _preferences.getString(_keyFor(userId));
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<void> write(String userId, String? teamId) async {
    final key = _keyFor(userId);
    if (teamId == null || teamId.isEmpty) {
      await _preferences.remove(key);
    } else {
      await _preferences.setString(key, teamId);
    }
  }
}
