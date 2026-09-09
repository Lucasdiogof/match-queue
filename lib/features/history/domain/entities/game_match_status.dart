/// Desfecho da partida que saiu de uma busca. Distinto de
/// [MatchSearchStatus], que descreve a busca: uma busca pode ter achado
/// partida e a partida terminar sem resultado informado.
enum GameMatchStatus {
  inMatch('IN_MATCH'),
  finished('FINISHED'),
  abandoned('ABANDONED'),
  expired('EXPIRED');

  const GameMatchStatus(this.key);

  final String key;

  static GameMatchStatus? fromKey(String? key) {
    for (final status in GameMatchStatus.values) {
      if (status.key == key) {
        return status;
      }
    }
    return null;
  }
}
