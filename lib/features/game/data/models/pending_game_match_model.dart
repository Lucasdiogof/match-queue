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
    );
  }
}
