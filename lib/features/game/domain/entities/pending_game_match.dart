import 'package:equatable/equatable.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';

/// Uma partida do usuário sem resultado e não dispensada.
class PendingGameMatch extends Equatable {
  const PendingGameMatch({
    required this.id,
    required this.teamId,
    required this.gameMode,
    required this.startedAt,
    this.weekendLeagueNumber,
    this.fcAccountName,
    this.fcSquadName,
    this.fcFormationCode,
    this.endedAt,
    this.teamName,
  });

  final String id;
  final String teamId;
  final GameMode gameMode;
  final DateTime startedAt;
  final int? weekendLeagueNumber;
  final String? fcAccountName;
  final String? fcSquadName;
  final String? fcFormationCode;

  /// Preenchido quando a partida ja foi encerrada sem resultado (expirou ou
  /// o usuario comecou outra). Continua reportavel ate ser dispensada.
  final DateTime? endedAt;

  final String? teamName;

  @override
  List<Object?> get props => <Object?>[
    id,
    teamId,
    gameMode,
    startedAt,
    weekendLeagueNumber,
    fcAccountName,
    fcSquadName,
    fcFormationCode,
    endedAt,
    teamName,
  ];
}
