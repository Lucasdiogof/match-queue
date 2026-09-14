import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_history_entry.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_rank.dart';
import 'package:fifa_queue/features/game/presentation/widgets/competitive_mode_card.dart';
import 'package:fifa_queue/features/game/presentation/widgets/weekend_league_rank_l10n.dart';
import 'package:flutter/material.dart';

/// Historico de Champions com selecao de semana -- setas em vez de lista
/// inteira, pra caber uma semana de cada vez no mesmo card competitivo.
/// Compartilhado entre o perfil de um companheiro de time e o perfil
/// publico -- os dois mostram a MESMA coisa, so a fonte do dado muda.
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
              IconButton(
                onPressed: index < history.length - 1
                    ? () => setState(() => _index = index + 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
                color: AppColors.darkTextPrimary,
                disabledColor: AppColors.darkTextSecondary,
              ),
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(
                      '#${entry.number}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.darkTextPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (entry.season != null)
                      Text(
                        entry.season!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.darkTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: index > 0
                    ? () => setState(() => _index = index - 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                color: AppColors.darkTextPrimary,
                disabledColor: AppColors.darkTextSecondary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (rank != null) ...<Widget>[
            AppBadge(label: rank.label),
            const SizedBox(height: AppSpacing.sm),
          ],
          Center(
            child: Text(
              '${entry.wins}–${entry.losses}',
              style: const TextStyle(
                color: AppColors.darkTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
