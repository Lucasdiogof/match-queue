import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/rivals_division.dart';
import 'package:fifa_queue/features/fc_accounts/domain/repositories/fc_account_repository.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_event.dart';

class FcAccountModel {
  const FcAccountModel._();

  static FcAccountsSnapshot snapshotFromResponse(Map<String, dynamic> json) {
    final rawAccounts = json['accounts'];
    final accounts = <FcAccount>[
      if (rawAccounts is List)
        for (final item in rawAccounts)
          if (item is Map) _fromJson(Map<String, dynamic>.from(item)),
    ];
    return FcAccountsSnapshot(
      accounts: accounts,
      weekendLeagueEvent: _eventFromJson(json['weekend_league_event']),
    );
  }

  static FcAccount _fromJson(Map<String, dynamic> json) {
    final manual = json['weekend_league_manual'];
    final manualWins = manual is Map ? manual['wins'] as int? : null;
    final manualLosses = manual is Map ? manual['losses'] as int? : null;
    final teamIds = json['team_ids'];
    return FcAccount(
      id: '${json['id']}',
      name: '${json['name']}',
      isActive: json['is_active'] as bool? ?? true,
      teamIds: teamIds is List
          ? teamIds.map((id) => '$id').toList(growable: false)
          : const <String>[],
      rivalsDivision: RivalsDivision.tryFromKey(json['rivals_division']),
      weekendLeagueComputedWins:
          json['weekend_league_computed_wins'] as int? ?? 0,
      weekendLeagueComputedLosses:
          json['weekend_league_computed_losses'] as int? ?? 0,
      weekendLeagueManualWins: manualWins,
      weekendLeagueManualLosses: manualLosses,
    );
  }

  static WeekendLeagueEvent? _eventFromJson(Object? json) {
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
      startsAt: DateTime.parse('${m['starts_at']}'),
      endsAt: DateTime.parse('${m['ends_at']}'),
    );
  }
}
