import 'package:shared_preferences/shared_preferences.dart';

class SelectedFcAccountStore {
  const SelectedFcAccountStore(this._preferences);

  final SharedPreferences _preferences;

  static const String _keyPrefix = 'fc_accounts.last_selected.';

  String _keyFor(String userId) => '$_keyPrefix$userId';

  String? read(String userId) {
    final value = _preferences.getString(_keyFor(userId));
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<void> write(String userId, String? accountId) async {
    final key = _keyFor(userId);
    if (accountId == null || accountId.isEmpty) {
      await _preferences.remove(key);
    } else {
      await _preferences.setString(key, accountId);
    }
  }
}
