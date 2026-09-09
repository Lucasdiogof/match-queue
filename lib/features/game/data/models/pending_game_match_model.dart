import 'package:fifa_queue/features/game/domain/entities/pending_game_match.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';

class PendingGameMatchModel {
  const PendingGameMatchModel._();

  static PendingGameMatch? fromResponse(Map<String, dynamic> json) {
    final match = json['match'];
    if (match is! Map) {
      return null;
    }
    final m = Map<String, dynamic>.from(match);
    return PendingGameMatch(
      id: '${m['id']}',
      teamId: '${m['team_id']}',
      gameMode: GameMode.fromKey(m['game_mode']),
      startedAt:
          DateTime.tryParse('${m['started_at']}')?.toLocal() ?? DateTime.now(),
      weekendLeagueNumber: m['weekend_league_number'] is int
          ? m['weekend_league_number'] as int
          : null,
      fcAccountName: m['fc_account_name'] as String?,
      fcSquadName: m['fc_squad_name'] as String?,
      fcFormationCode: m['fc_formation_code'] as String?,
    );
  }

  /// Uma linha de list_pending_game_matches. Nao traz formacao (a lista nao
  /// precisa) e traz ended_at, que so existe quando a partida ja fechou sem
  /// resultado.
  static PendingGameMatch? fromListItem(Object? item) {
    if (item is! Map) {
      return null;
    }
    final m = Map<String, dynamic>.from(item);
    final id = m['id'];
    if (id == null) {
      return null;
    }
    return PendingGameMatch(
      id: '$id',
      teamId: '${m['team_id']}',
      gameMode: GameMode.fromKey(m['game_mode']),
      startedAt:
          DateTime.tryParse('${m['started_at']}')?.toLocal() ?? DateTime.now(),
      endedAt: DateTime.tryParse('${m['ended_at']}')?.toLocal(),
      weekendLeagueNumber: m['weekend_league_number'] is int
          ? m['weekend_league_number'] as int
          : null,
      fcAccountName: m['fc_account_name'] as String?,
      fcSquadName: m['fc_squad_name'] as String?,
      teamName: m['team_name'] as String?,
    );
  }
}
