import 'package:fifa_queue/features/account/domain/entities/account.dart';
import 'package:fifa_queue/features/account/domain/entities/platform.dart';
import 'package:fifa_queue/features/account/domain/entities/rivals_division.dart';
import 'package:fifa_queue/features/game/data/models/weekend_league_event_model.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_event.dart';

class AccountModel {
  const AccountModel._();

  static const String table = 'profiles';
  static const String columnId = 'id';
  static const String columnDisplayName = 'display_name';
  static const String columnAvatarUrl = 'avatar_url';
  static const String columnLocale = 'locale';
  static const String columnLastActiveAt = 'last_active_at';
  static const String columnPlatforms = 'platforms';
  static const String columnRivalsDivision = 'rivals_division';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  static Account fromJson(Map<String, dynamic> json) {
    final createdAt = _parseDate(json[columnCreatedAt]);
    return Account(
      id: '${json[columnId]}',
      displayName: '${json[columnDisplayName]}',
      avatarUrl: _parseString(json[columnAvatarUrl]),
      locale: _parseString(json[columnLocale]),
      platforms: _parsePlatforms(json[columnPlatforms]),
      rivalsDivision: RivalsDivision.tryFromKey(json[columnRivalsDivision]),
      createdAt: createdAt,
      updatedAt: _parseDate(json[columnUpdatedAt], fallback: createdAt),
    );
  }

  /// Mescla o bundle de `get_my_account` (times, record manual, evento
  /// vigente) em cima de um [Account] ja carregado da tabela `profiles`.
  static Account mergeExtras(Account base, Map<String, dynamic> json) {
    final manual = json['weekend_league_manual'];
    final rivalsManual = json['rivals_manual'];
    final teamIds = json['team_ids'];
    return Account(
      id: base.id,
      displayName: base.displayName,
      avatarUrl: base.avatarUrl,
      locale: base.locale,
      platforms: base.platforms,
      rivalsDivision: base.rivalsDivision,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      teamIds: teamIds is List
          ? teamIds.map((id) => '$id').toList(growable: false)
          : const <String>[],
      weekendLeagueManualWins: manual is Map ? manual['wins'] as int? : null,
      weekendLeagueManualLosses: manual is Map
          ? manual['losses'] as int?
          : null,
      rivalsWins: rivalsManual is Map ? rivalsManual['wins'] as int? ?? 0 : 0,
      rivalsLosses: rivalsManual is Map
          ? rivalsManual['losses'] as int? ?? 0
          : 0,
      weekendLeagueEvent: _eventFromJson(json['weekend_league_event']),
    );
  }

  static WeekendLeagueEvent? _eventFromJson(Object? json) =>
      WeekendLeagueEventModel.fromResponse(json);

  static List<Platform> _parsePlatforms(Object? value) {
    if (value is! List) {
      return const <Platform>[];
    }
    return <Platform>[
      for (final entry in value)
        if (Platform.tryFromKey(entry) != null) Platform.tryFromKey(entry)!,
    ];
  }

  static DateTime _parseDate(Object? value, {DateTime? fallback}) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed.toUtc();
      }
    }
    return fallback ?? DateTime.now().toUtc();
  }

  static String? _parseString(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
