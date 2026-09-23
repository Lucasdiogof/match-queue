import 'package:fifa_queue/features/notifications/domain/entities/notification_preferences.dart';

class NotificationPreferencesModel {
  const NotificationPreferencesModel._();

  static const String table = 'notification_preferences';
  static const String columnUserId = 'user_id';
  static const String columnQueueTurn = 'queue_turn_enabled';
  static const String columnSearchExpiring = 'search_expiring_enabled';
  static const String columnSearchExpired = 'search_expired_enabled';
  static const String columnMatchmaking = 'matchmaking_enabled';
  static const String columnTeams = 'teams_enabled';
  static const String columnWeekendLeague = 'weekend_league_enabled';
  static const String columnRivals = 'rivals_enabled';
  static const String columnRankings = 'rankings_enabled';

  static NotificationPreferences fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        queueTurnEnabled: _bool(json[columnQueueTurn]),
        searchExpiringEnabled: _bool(json[columnSearchExpiring]),
        searchExpiredEnabled: _bool(json[columnSearchExpired]),
        matchmakingEnabled: _bool(json[columnMatchmaking]),
        teamsEnabled: _bool(json[columnTeams]),
        weekendLeagueEnabled: _bool(json[columnWeekendLeague]),
        rivalsEnabled: _bool(json[columnRivals]),
        rankingsEnabled: _bool(json[columnRankings]),
      );

  static Map<String, dynamic> toJson(
    String userId,
    NotificationPreferences preferences,
  ) => <String, dynamic>{
    columnUserId: userId,
    columnQueueTurn: preferences.queueTurnEnabled,
    columnSearchExpiring: preferences.searchExpiringEnabled,
    columnSearchExpired: preferences.searchExpiredEnabled,
    columnMatchmaking: preferences.matchmakingEnabled,
    columnTeams: preferences.teamsEnabled,
    columnWeekendLeague: preferences.weekendLeagueEnabled,
    columnRivals: preferences.rivalsEnabled,
    columnRankings: preferences.rankingsEnabled,
  };

  /// Coluna ausente ou nula significa habilitado -- mesmo default do banco.
  static bool _bool(Object? value) => value is bool ? value : true;
}
