import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_history_entry.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_rank.dart';
import 'package:fifa_queue/features/game/presentation/widgets/competitive_mode_card.dart';
import 'package:fifa_queue/features/game/presentation/widgets/weekend_league_rank_l10n.dart';
import 'package:flutter/material.dart';

class WeekendLeagueHistoryCard extends StatefulWidget {
  const WeekendLeagueHistoryCard({required this.history, super.key});

  final List<WeekendLeagueHistoryEntry> history;

  @override
  State<WeekendLeagueHistoryCard> createState() =>
      _WeekendLeagueHistoryCardState();
}

class _WeekendLeagueHistoryCardState extends State<WeekendLeagueHistoryCard> {
  late int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final history = widget.history;

    if (history.isEmpty) {
      return CompetitiveModeCard(
        mode: CompetitiveMode.champions,
        title: l10n.fcAccountWeekendLeagueTitle,
        child: Text(
          l10n.playerProfileWeekendLeagueEmptyMessage,
          style: const TextStyle(color: AppColors.darkTextSecondary),
        ),
      );
    }

    final index = _index.clamp(0, history.length - 1);
    final entry = history[index];
    final rank = WeekendLeagueRank.fromWins(entry.wins);

    return CompetitiveModeCard(
      mode: CompetitiveMode.champions,
      title: l10n.fcAccountWeekendLeagueTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (rank != null)
                      Text(
                        rank.label.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.darkTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '${entry.wins}–${entry.losses}',
                style: const TextStyle(
                  color: AppColors.darkTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              IconButton(
                onPressed: index < history.length - 1
                    ? () => setState(() => _index = index + 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
                color: AppColors.darkTextPrimary,
                disabledColor: AppColors.darkTextSecondary,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _dateRange(context, entry),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: index > 0
                    ? () => setState(() => _index = index - 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                color: AppColors.darkTextPrimary,
                disabledColor: AppColors.darkTextSecondary,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _dateRange(BuildContext context, WeekendLeagueHistoryEntry entry) {
    final l10n = context.l10n;
    final start = l10n.historyEntryDate(entry.startsAt);
    if (entry.endsAt != null) {
      final end = l10n.historyEntryDate(entry.endsAt!);
      return '#${entry.number} · $start – $end';
    }
    return '#${entry.number} · $start';
  }
}
