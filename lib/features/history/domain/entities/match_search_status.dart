/// Desfecho de uma sessão de busca já concluída. SEARCHING nunca aparece no
/// histórico nem nas estatísticas — só entra sessão com `finished_at`.
enum MatchSearchStatus {
  matchFound('MATCH_FOUND'),
  cancelled('CANCELLED'),
  expired('EXPIRED');

  const MatchSearchStatus(this.key);

  final String key;

  static MatchSearchStatus? fromKey(Object? key) {
    for (final status in MatchSearchStatus.values) {
      if (status.key == key) {
        return status;
      }
    }
    return null;
  }
}
