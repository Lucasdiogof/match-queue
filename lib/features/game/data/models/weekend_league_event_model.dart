import 'package:fifa_queue/features/game/domain/entities/weekend_league_event.dart';

class WeekendLeagueEventModel {
  const WeekendLeagueEventModel._();

  static WeekendLeagueEvent? fromResponse(Object? json) {
    if (json is! Map) {
      return null;
    }
    final m = Map<String, dynamic>.from(json);
    final id = m['id'];
    if (id == null) {
      return null;
    }
    return WeekendLeagueEvent(
      id: '$id',
      number: m['number'] is int ? m['number'] as int : 0,
      season: m['season'] as String?,
      startsAt: DateTime.parse('${m['starts_at']}'),
      endsAt: DateTime.parse('${m['ends_at']}'),
    );
  }
}
