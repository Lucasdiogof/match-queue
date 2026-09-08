import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/rivals_division.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_event.dart';

class FcAccountsSnapshot {
  const FcAccountsSnapshot({required this.accounts, this.weekendLeagueEvent});

  final List<FcAccount> accounts;
  final WeekendLeagueEvent? weekendLeagueEvent;
}

abstract interface class FcAccountRepository {
  Future<FcAccountsSnapshot> fetchMyAccounts();

  Future<void> createAccount(String name);

  Future<void> updateAccount({required String id, required String name});

  Future<void> archiveAccount(String id);

  Future<void> updateRivalsDivision({
    required String id,
    RivalsDivision? division,
  });

  Future<void> linkToTeam({required String accountId, required String teamId});

  Future<void> unlinkFromTeam({
    required String accountId,
    required String teamId,
  });

  Future<void> setWeekendLeagueManualRecord({
    required String accountId,
    required String eventId,
    required int wins,
    required int losses,
  });

  Future<void> clearWeekendLeagueManualRecord({
    required String accountId,
    required String eventId,
  });
}
