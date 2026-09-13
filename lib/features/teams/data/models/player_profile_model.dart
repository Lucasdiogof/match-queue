import 'package:fifa_queue/features/fc_squads/data/models/fc_squad_model.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/teams/domain/entities/player_profile.dart';

class PlayerProfileModel {
  const PlayerProfileModel._();

  static PlayerProfileSquad? _squadFromJson(Object? json) {
    if (json is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(json);
    final formationJson = map['formation'];
    if (formationJson is! Map) {
      return null;
    }
    final startersJson =
        map['starters'] as List<dynamic>? ?? const <dynamic>[];
    return PlayerProfileSquad(
      name: '${map['name']}',
      formation: FcSquadModel.formationFromJson(
        Map<String, dynamic>.from(formationJson),
      ),
      starters: <String, PlayerCard>{
        for (final row in startersJson.whereType<Map<String, dynamic>>())
          if (row['card'] is Map)
            '${row['slot_code']}': FcSquadModel.cardFromJson(
              Map<String, dynamic>.from(row['card'] as Map),
            ),
      },
    );
  }

  static PlayerProfile fromJson(Map<String, dynamic> json) {
    final candidatesJson =
        json['candidate_accounts'] as List<dynamic>? ?? const <dynamic>[];
    final accountJson = json['account'] as Map<String, dynamic>?;
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
              rivalsWins: accountJson['rivals_wins'] as int? ?? 0,
              rivalsLosses: accountJson['rivals_losses'] as int? ?? 0,
            ),
      squad: _squadFromJson(json['squad']),
      weekendLeagueHistory: wlJson
          .whereType<Map<String, dynamic>>()
          .map(
            (row) => PlayerProfileWeekendLeagueEntry(
              eventId: '${row['event_id']}',
              number: row['number'] as int? ?? 0,
              season: row['season'] as String?,
              startsAt: DateTime.parse('${row['starts_at']}'),
              wins: row['wins'] as int? ?? 0,
              losses: row['losses'] as int? ?? 0,
            ),
          )
          .toList(growable: false),
    );
  }
}
