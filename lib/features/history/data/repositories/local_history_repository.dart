import 'package:fifa_queue/features/history/domain/entities/match_history_entry.dart';
import 'package:fifa_queue/features/history/domain/entities/match_history_page.dart';
import 'package:fifa_queue/features/history/domain/entities/match_search_status.dart';
import 'package:fifa_queue/features/history/domain/entities/matchmaking_stats.dart';
import 'package:fifa_queue/features/history/domain/repositories/history_repository.dart';

/// Modo local de desenvolvimento (sem Supabase): não há histórico real porque
/// não há backend registrando sessões. Devolve vazio honesto — mesma postura
/// do `LocalMatchmakingRepository`.
class LocalHistoryRepository implements HistoryRepository {
  const LocalHistoryRepository();

  @override
  Future<MatchHistoryPage> fetchHistory({
    required String teamId,
    int limit = 20,
    MatchHistoryCursor? cursor,
    MatchSearchStatus? status,
    String? userId,
    DateTime? from,
    DateTime? to,
  }) async => MatchHistoryPage(
    items: const <MatchHistoryEntry>[],
    hasMore: false,
    serverNow: DateTime.now().toUtc(),
  );

  @override
  Future<MatchmakingStats> fetchStats({
    required String teamId,
    DateTime? from,
    DateTime? to,
  }) async => MatchmakingStats(
    totals: const MatchmakingTotals(
      total: 0,
      matchFound: 0,
      cancelled: 0,
      expired: 0,
    ),
    players: const <PlayerStats>[],
    serverNow: DateTime.now().toUtc(),
  );
}
