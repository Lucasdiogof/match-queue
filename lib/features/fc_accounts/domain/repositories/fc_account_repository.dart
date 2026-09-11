import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account_stats.dart';
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

  /// Delta pode ser negativo (corrigir um toque em "+" a mais). Servidor
  /// nunca deixa o total ficar negativo nem passar de 15 jogos.
  Future<void> incrementWeekendLeagueManualRecord({
    required String accountId,
    required String eventId,
    int winDelta = 0,
    int lossDelta = 0,
  });

  Future<void> incrementRivalsManualRecord({
    required String accountId,
    int winDelta = 0,
    int lossDelta = 0,
  });

  /// Partidas registradas/W/L/gols pró-contra-saldo da conta, todos os modos.
  Future<FcAccountStats> fetchAccountStats(String accountId);

  /// Record de WL (computado x manual), artilharia e assistências de uma
  /// conta num evento.
  /// Semanas de Weekend League ja iniciadas, mais recente primeiro.
  Future<List<WeekendLeagueEvent>> fetchWeekendLeagueEvents();

  Future<WeekendLeagueAccountStats> fetchWeekendLeagueAccountStats({
    required String accountId,
    required String eventId,
  });

  /// Partidas/record/gols/assistências de Rivals de uma conta. All-time
  /// (sem season/semana modelada ainda).
  Future<RivalsAccountStats> fetchRivalsAccountStats(String accountId);
}
