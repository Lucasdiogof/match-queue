import 'package:equatable/equatable.dart';
import 'package:fifa_queue/features/history/domain/entities/match_history_entry.dart';

/// Cursor keyset: o par (finished_at, id) da última linha entregue. A próxima
/// página pede estritamente o que vem depois dele, sem OFFSET.
class MatchHistoryCursor extends Equatable {
  const MatchHistoryCursor({required this.finishedAt, required this.id});

  final String finishedAt;
  final String id;

  @override
  List<Object?> get props => <Object?>[finishedAt, id];
}

class MatchHistoryPage extends Equatable {
  const MatchHistoryPage({
    required this.items,
    required this.hasMore,
    required this.serverNow,
    this.nextCursor,
  });

  final List<MatchHistoryEntry> items;
  final bool hasMore;
  final MatchHistoryCursor? nextCursor;
  final DateTime serverNow;

  @override
  List<Object?> get props => <Object?>[items, hasMore, nextCursor, serverNow];
}
