import 'package:equatable/equatable.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';

/// Uma partida IN_MATCH do usuário, pendente de resultado.
class PendingGameMatch extends Equatable {
  const PendingGameMatch({
    required this.id,
    required this.teamId,
    required this.gameMode,
    required this.startedAt,
    this.weekendLeagueNumber,
  });

  final String id;
  final String teamId;
  final GameMode gameMode;
  final DateTime startedAt;
  final int? weekendLeagueNumber;

  @override
  List<Object?> get props => <Object?>[
    id,
    teamId,
    gameMode,
    startedAt,
    weekendLeagueNumber,
  ];
}
