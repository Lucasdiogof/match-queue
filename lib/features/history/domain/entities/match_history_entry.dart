import 'package:equatable/equatable.dart';
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
  ];
}
