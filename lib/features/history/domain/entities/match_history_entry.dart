import 'package:equatable/equatable.dart';
import 'package:fifa_queue/features/game/domain/entities/game_result.dart';
import 'package:fifa_queue/features/history/domain/entities/game_match_status.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';
import 'package:fifa_queue/features/history/domain/entities/match_search_status.dart';

class MatchHistoryEntry extends Equatable {
  const MatchHistoryEntry({
    required this.sessionId,
    required this.userId,
    required this.displayName,
    required this.status,
    required this.startedAt,
    required this.finishedAt,
    required this.durationSeconds,
    required this.configuredDurationSeconds,
    this.avatarUrl,
    this.finishReason,
    this.gameMode,
    this.fcAccountName,
    this.matchStatus,
    this.matchStartedAt,
    this.result,
    this.goalsFor,
    this.goalsAgainst,
  });

  final String sessionId;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final MatchSearchStatus status;
  final String? finishReason;
  final DateTime startedAt;
  final DateTime finishedAt;

  /// Quanto a busca realmente durou (relógio do servidor).
  final int durationSeconds;

  /// A janela que a sessão recebeu ao nascer — a duração configurada do time
  /// naquele momento, não a atual.
  final int configuredDurationSeconds;

  /// Modalidade da busca (WEEKEND_LEAGUE / DIVISION_RIVALS). Null em sessoes
  /// anteriores ao modo existir.
  final GameMode? gameMode;

  /// Conta FC que buscou. Null quando a conta foi apagada ou a sessao e
  /// anterior ao vinculo com contas.
  final String? fcAccountName;

  final GameMatchStatus? matchStatus;
  final DateTime? matchStartedAt;

  /// Null quando o jogador nao informou o resultado -- nunca derrota. Ver
  /// [hasMatch] para distinguir "sem partida" de "partida sem resultado".
  final GameResult? result;
  final int? goalsFor;
  final int? goalsAgainst;

  bool get hasMatch => matchStatus != null;

  bool get hasScore => goalsFor != null && goalsAgainst != null;

  /// Partida que aconteceu e nunca foi registrada. A tela mostra um rotulo
  /// neutro nesse caso, jamais um resultado inventado.
  bool get isResultUnreported => hasMatch && result == null;

  @override
  List<Object?> get props => <Object?>[
    sessionId,
    userId,
    displayName,
    avatarUrl,
    status,
    finishReason,
    startedAt,
    finishedAt,
    durationSeconds,
    configuredDurationSeconds,
    gameMode,
    fcAccountName,
    matchStatus,
    matchStartedAt,
    result,
    goalsFor,
    goalsAgainst,
  ];
}
