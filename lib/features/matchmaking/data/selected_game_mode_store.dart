import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lembra o último modo escolhido, localmente. Preferência do dispositivo, não
/// fonte da verdade — a busca real carrega o modo na própria session.
class SelectedGameModeStore {
  const SelectedGameModeStore(this._preferences);

  final SharedPreferences _preferences;

  static const String _key = 'matchmaking.selected_game_mode';

  GameMode read() =>
      GameMode.tryFromKey(_preferences.getString(_key)) ??
      GameMode.weekendLeague;

  Future<void> write(GameMode mode) => _preferences.setString(_key, mode.key);
}
