import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account_stats.dart';
import 'package:fifa_queue/features/game/domain/entities/player_leaderboard_entry.dart';
import 'package:fifa_queue/features/teams/domain/entities/player_profile.dart';

class PlayerProfileModel {
  const PlayerProfileModel._();

  static PlayerProfile fromJson(Map<String, dynamic> json) {
    final candidatesJson =
        json['candidate_accounts'] as List<dynamic>? ?? const <dynamic>[];
    final accountJson = json['account'] as Map<String, dynamic>?;
    final squadJson = json['squad'] as Map<String, dynamic>?;
    final wlJson =
        json['weekend_league_history'] as List<dynamic>? ?? const <dynamic>[];

    return PlayerProfile(
      userId: '${json['user_id']}',
      displayName: '${json['display_name']}',
      avatarUrl: json['avatar_url'] as String?,
      candidateAccounts: candidatesJson
          .whereType<Map<String, dynamic>>()
          .map(
            (row) => PlayerProfileAccountCandidate(
              id: '${row['id']}',
              name: '${row['name']}',
            ),
          )
          .toList(growable: false),
      needsAccountSelection: json['needs_account_selection'] as bool? ?? false,
      account: accountJson == null
          ? null
          : PlayerProfileAccount(
              id: '${accountJson['id']}',
              name: '${accountJson['name']}',
              rivalsDivision: accountJson['rivals_division'] as String?,
            ),
      squad: squadJson == null
          ? null
          : PlayerProfileSquadSummary(
              id: '${squadJson['id']}',
              name: '${squadJson['name']}',
              formationCode: '${squadJson['formation_code']}',
              startingCount: squadJson['starting_count'] as int? ?? 0,
              startingTotal: squadJson['starting_total'] as int? ?? 11,
            ),
      weekendLeagueHistory: wlJson
          .whereType<Map<String, dynamic>>()
          .map(
            (row) => PlayerProfileWeekendLeagueEntry(
              eventId: '${row['event_id']}',
              number: row['number'] as int? ?? 0,
              season: row['season'] as int? ?? 0,
              startsAt: DateTime.parse('${row['starts_at']}'),
              wins: row['wins'] as int? ?? 0,
              losses: row['losses'] as int? ?? 0,
            ),
          )
          .toList(growable: false),
      sportSummary: json['sport_summary'] == null
          ? null
          : PlayerProfileSportSummary(
              rivals: FcAccountStats.fromJson(
                (json['sport_summary'] as Map<String, dynamic>)['rivals'],
              ),
              topScorers: PlayerLeaderboardEntry.listFromJson(
                (json['sport_summary'] as Map<String, dynamic>)['top_scorers'],
              ),
              topAssists: PlayerLeaderboardEntry.listFromJson(
                (json['sport_summary'] as Map<String, dynamic>)['top_assists'],
              ),
            ),
    );
  }
}
