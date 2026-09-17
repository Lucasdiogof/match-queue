import 'package:fifa_queue/features/account/domain/entities/account.dart';
import 'package:fifa_queue/features/account/domain/entities/account_stats.dart';
import 'package:fifa_queue/features/account/domain/entities/platform.dart';
import 'package:fifa_queue/features/account/domain/entities/rivals_division.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_event.dart';

abstract interface class AccountRepository {
  Future<Account?> fetchMyAccount();

  Future<Account> ensureMyAccount({required String fallbackDisplayName});

  Future<Account> updateDisplayName(String displayName);

  /// Escrita pura de `profiles.locale`, usada só para o worker de push saber
  /// em que idioma redigir a notificação. Nunca é lida de volta pelo app: a
  /// fonte da verdade do idioma na UI é a preferência local (LocaleCubit).
  Future<void> updateLocale(String localeTag);

  /// Heartbeat de atividade recente -- escrita espaçada, nunca a cada
  /// segundo. Nunca lida de volta pela UI: quem consome last_active_at é
  /// get_team_player_statuses, do lado dos outros membros.
  Future<void> touchActivity();

  /// Substitui as plataformas da conta. Nunca aceita lista vazia -- o
  /// servidor recusa (FQ058).
  Future<List<Platform>> updatePlatforms(List<Platform> platforms);

  Future<void> updateRivalsDivision(RivalsDivision? division);

  Future<void> incrementRivalsRecord({int winDelta = 0, int lossDelta = 0});

  Future<void> incrementWeekendLeagueRecord({
    required String eventId,
    int winDelta = 0,
    int lossDelta = 0,
  });

  Future<void> setWeekendLeagueManualRecord({
    required String eventId,
    required int wins,
    required int losses,
  });

  Future<void> clearWeekendLeagueManualRecord(String eventId);

  Future<List<WeekendLeagueEvent>> fetchWeekendLeagueEvents();

  Future<WeekendLeagueAccountStats> fetchWeekendLeagueStats(String eventId);

  Future<RivalsAccountStats> fetchRivalsStats();
}
