/// Modo de jogo de uma busca/partida. V1: Weekend League e Division Rivals.
enum GameMode {
  weekendLeague('WEEKEND_LEAGUE'),
  divisionRivals('DIVISION_RIVALS');

  const GameMode(this.key);

  final String key;

  static GameMode fromKey(Object? key) {
    for (final mode in GameMode.values) {
      if (mode.key == key) {
        return mode;
      }
    }
    return GameMode.divisionRivals;
  }

  static GameMode? tryFromKey(Object? key) {
    for (final mode in GameMode.values) {
      if (mode.key == key) {
        return mode;
      }
    }
    return null;
  }
}
