/// Sinal de que o estado do time mudou -- nunca o estado em si.
///
/// O cliente jamais deriva "quem foi promovido" de um evento: ele so
/// descobre que precisa reler get_team_matchmaking_state, que continua
/// sendo a unica fonte de verdade. Por isso evento repetido, fora de ordem
/// ou atrasado e inofensivo: no pior caso provoca uma releitura a mais.
sealed class MatchmakingRealtimeEvent {
  const MatchmakingRealtimeEvent();
}

/// O canal entrou no ar. Depois de uma reconexao isso tambem significa
/// "posso ter perdido eventos enquanto estive fora" -- o cubit reconcilia.
final class MatchmakingSubscribed extends MatchmakingRealtimeEvent {
  const MatchmakingSubscribed();
}

/// Algo mudou no matchmaking deste time.
final class MatchmakingStateInvalidated extends MatchmakingRealtimeEvent {
  const MatchmakingStateInvalidated({this.revision});

  /// Contador monotonico do servidor. Serve so para log/diagnostico.
  final int? revision;
}

/// Canal caiu ou falhou. A UI continua mostrando o ultimo estado bom.
final class MatchmakingRealtimeLost extends MatchmakingRealtimeEvent {
  const MatchmakingRealtimeLost();
}
