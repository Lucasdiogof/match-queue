import 'package:fifa_queue/features/teams/domain/entities/team_sports_dashboard.dart';

class TeamSportsDashboardModel {
  const TeamSportsDashboardModel._();

  static int _toInt(Object? v) => switch (v) {
    final int n => n,
    final num n => n.toInt(),
    final String s => int.tryParse(s) ?? 0,
    _ => 0,
  };

  static double? _toDouble(Object? v) => switch (v) {
    null => null,
    final num n => n.toDouble(),
    final String s => double.tryParse(s),
    _ => null,
  };

  static List<Map<String, dynamic>> _list(Object? v) => <Map<String, dynamic>>[
    if (v is List)
      for (final item in v)
        if (item is Map) Map<String, dynamic>.from(item),
  ];

  static TeamSportsDashboard fromJson(Map<String, dynamic> json) {
    final summary = json['summary'];

    return TeamSportsDashboard(
      teamId: '${json['team_id']}',
      minRankedMatches: _toInt(json['min_ranked_matches']),
      summary: _summaryFromJson(
        summary is Map ? Map<String, dynamic>.from(summary) : const {},
      ),
      ranking: _list(
        json['ranking'],
      ).map(_memberFromJson).toList(growable: false),
      topScorers: _list(
        json['top_scorers'],
      ).map(_leaderboardFromJson).toList(growable: false),
      topAssists: _list(
        json['top_assists'],
      ).map(_leaderboardFromJson).toList(growable: false),
      weekendLeague: _list(
        json['weekend_league'],
      ).map(_weekendLeagueFromJson).toList(growable: false),
      rivals: _list(
        json['rivals'],
      ).map(_rivalsFromJson).toList(growable: false),
      activity: _list(
        json['activity'],
      ).map(_activityFromJson).toList(growable: false),
    );
  }

  static TeamSportsSummary _summaryFromJson(Map<String, dynamic> json) =>
      TeamSportsSummary(
        membersCount: _toInt(json['members_count']),
        accountsCount: _toInt(json['accounts_count']),
        matches: _toInt(json['matches']),
        wins: _toInt(json['wins']),
        losses: _toInt(json['losses']),
        winRate: _toDouble(json['win_rate']),
        goalsFor: _toInt(json['goals_for']),
        goalsAgainst: _toInt(json['goals_against']),
        goalDifference: _toInt(json['goal_difference']),
        registeredPlayerGoals: _toInt(json['registered_player_goals']),
        registeredAssists: _toInt(json['registered_assists']),
      );

  static TeamMemberSportsStats _memberFromJson(Map<String, dynamic> json) =>
      TeamMemberSportsStats(
        userId: '${json['user_id']}',
        displayName: '${json['display_name'] ?? ''}',
        avatarUrl: json['avatar_url'] as String?,
        accountsCount: _toInt(json['accounts_count']),
        matches: _toInt(json['matches']),
        wins: _toInt(json['wins']),
        losses: _toInt(json['losses']),
        winRate: _toDouble(json['win_rate']),
        goalsFor: _toInt(json['goals_for']),
        goalsAgainst: _toInt(json['goals_against']),
        playerGoals: _toInt(json['player_goals']),
        playerAssists: _toInt(json['player_assists']),
        isRanked: json['is_ranked'] as bool? ?? false,
      );

  static TeamPlayerLeaderboardEntry _leaderboardFromJson(
    Map<String, dynamic> json,
  ) => TeamPlayerLeaderboardEntry(
    playerKey: '${json['player_key']}',
    playerCardId: json['player_card_id'] as String?,
    playerName: '${json['player_name'] ?? ''}',
    goals: _toInt(json['goals']),
    assists: _toInt(json['assists']),
    userId: '${json['user_id']}',
    displayName: '${json['display_name'] ?? ''}',
    fcAccountId: '${json['fc_account_id']}',
    accountName: '${json['account_name'] ?? ''}',
  );

  static TeamWeekendLeagueEntry _weekendLeagueFromJson(
    Map<String, dynamic> json,
  ) => TeamWeekendLeagueEntry(
    userId: '${json['user_id']}',
    displayName: '${json['display_name'] ?? ''}',
    fcAccountId: '${json['fc_account_id']}',
    accountName: '${json['account_name'] ?? ''}',
    wins: _toInt(json['wins']),
    losses: _toInt(json['losses']),
    isManual: json['is_manual'] as bool? ?? false,
  );

  static TeamRivalsEntry _rivalsFromJson(Map<String, dynamic> json) =>
      TeamRivalsEntry(
        userId: '${json['user_id']}',
        displayName: '${json['display_name'] ?? ''}',
        fcAccountId: '${json['fc_account_id']}',
        accountName: '${json['account_name'] ?? ''}',
        division: json['division'] as String?,
        matches: _toInt(json['matches']),
        wins: _toInt(json['wins']),
        losses: _toInt(json['losses']),
        winRate: _toDouble(json['win_rate']),
      );

  static TeamSportsActivity _activityFromJson(Map<String, dynamic> json) {
    final scorer = json['top_scorer'];
    final scorerMap = scorer is Map ? Map<String, dynamic>.from(scorer) : null;
    return TeamSportsActivity(
      occurredAt: DateTime.parse('${json['occurred_at']}'),
      userId: '${json['user_id']}',
      displayName: '${json['display_name'] ?? ''}',
      avatarUrl: json['avatar_url'] as String?,
      accountName: '${json['account_name'] ?? ''}',
      gameMode: '${json['game_mode']}',
      result: '${json['result']}',
      goalsFor: json['goals_for'] == null ? null : _toInt(json['goals_for']),
      goalsAgainst: json['goals_against'] == null
          ? null
          : _toInt(json['goals_against']),
      topScorerName: scorerMap?['player_name'] as String?,
      topScorerGoals: scorerMap == null ? null : _toInt(scorerMap['goals']),
    );
  }

  static List<TeamPlayerLeaderboardEntry> leaderboardFromResponse(
    Object? json,
  ) => _list(json).map(_leaderboardFromJson).toList(growable: false);
}
