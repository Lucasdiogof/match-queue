import 'package:fifa_queue/features/game/domain/entities/game_match_details.dart';
import 'package:fifa_queue/features/game/domain/entities/game_result.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';

class GameMatchDetailsModel {
  const GameMatchDetailsModel._();

  static GameMatchDetails fromResponse(Map<String, dynamic> json) {
    final m = Map<String, dynamic>.from(json['match'] as Map);
    final statsJson = json['player_stats'];
    final resultKey = m['result'] as String?;

    return GameMatchDetails(
      id: '${m['id']}',
      teamId: '${m['team_id']}',
      gameMode: GameMode.fromKey(m['game_mode']),
      status: '${m['status']}',
      result: resultKey == 'WIN'
          ? GameResult.win
          : resultKey == 'LOSS'
          ? GameResult.loss
          : null,
      goalsFor: m['goals_for'] as int?,
      goalsAgainst: m['goals_against'] as int?,
      startedAt:
          DateTime.tryParse('${m['started_at']}')?.toLocal() ?? DateTime.now(),
      endedAt: m['ended_at'] == null
          ? null
          : DateTime.tryParse('${m['ended_at']}')?.toLocal(),
      weekendLeagueEventId: m['weekend_league_event_id'] as String?,
      fcAccountId: m['fc_account_id'] as String?,
      fcAccountName: m['fc_account_name'] as String?,
      fcSquadId: m['fc_squad_id'] as String?,
      squadSnapshot: SquadSnapshot.fromJson(m['squad_snapshot']),
      playerStats: statsJson is List
          ? statsJson
                .whereType<Map<String, dynamic>>()
                .map(GameMatchPlayerStat.fromJson)
                .toList(growable: false)
          : const <GameMatchPlayerStat>[],
      isOwner: json['is_owner'] as bool? ?? false,
    );
  }
}
