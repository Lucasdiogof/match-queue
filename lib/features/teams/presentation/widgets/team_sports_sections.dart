import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_sports_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatWinRate(BuildContext context, double? rate) {
  if (rate == null) {
    return '—';
  }
  return NumberFormat.percentPattern(
    Localizations.localeOf(context).toLanguageTag(),
  ).format(rate);
}

class TeamSportsSummarySection extends StatelessWidget {
  const TeamSportsSummarySection({required this.summary, super.key});

  final TeamSportsSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (!summary.hasMatches) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.teamSportsSummaryTitle.toUpperCase(),
              style: context.textStyles.labelSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            // Time novo mostra uma frase, não uma parede de zeros (item 44).
            Text(
              l10n.teamSportsNoMatchesYet,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.teamSportsSummaryTitle.toUpperCase(),
          style: context.textStyles.labelSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            Expanded(
              child: _StatTile(
                label: l10n.teamSportsMatches,
                value: '${summary.matches}',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatTile(
                label: l10n.teamSportsWins,
                value: '${summary.wins}',
                tone: AppBadgeTone.success,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatTile(
                label: l10n.teamSportsLosses,
                value: '${summary.losses}',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatTile(
                label: l10n.teamSportsWinRate,
                value: formatWinRate(context, summary.winRate),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            Expanded(
              child: _StatTile(
                label: l10n.teamSportsGoalsFor,
                value: '${summary.goalsFor}',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatTile(
                label: l10n.teamSportsGoalsAgainst,
                value: '${summary.goalsAgainst}',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatTile(
                label: l10n.teamSportsGoalDifference,
                value: summary.goalDifference > 0
                    ? '+${summary.goalDifference}'
                    : '${summary.goalDifference}',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    this.tone = AppBadgeTone.neutral,
  });

  final String label;
  final String value;
  final AppBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.titleLarge?.copyWith(
              color: tone == AppBadgeTone.success
                  ? colors.success
                  : colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.bodySmall?.copyWith(
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class TeamWeekendLeagueSection extends StatelessWidget {
  const TeamWeekendLeagueSection({required this.entries, super.key});

  final List<TeamWeekendLeagueEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final withRecord = entries.where((e) => e.hasRecord).toList();
    if (withRecord.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.teamSportsWeekendLeagueTitle.toUpperCase(),
            style: context.textStyles.labelSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final entry in withRecord)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          entry.displayName,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.bodyLarge,
                        ),
                        Text(
                          entry.accountName,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (entry.isManual) ...<Widget>[
                    AppBadge(label: l10n.teamSportsManualRecord),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    '${entry.wins}–${entry.losses}',
                    style: context.textStyles.titleMedium,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class TeamRivalsSection extends StatelessWidget {
  const TeamRivalsSection({required this.entries, super.key});

  final List<TeamRivalsEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final relevant = entries
        .where((e) => e.hasRecord || e.division != null)
        .toList();
    if (relevant.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.teamSportsRivalsTitle.toUpperCase(),
            style: context.textStyles.labelSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final entry in relevant)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          entry.displayName,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.bodyLarge,
                        ),
                        Text(
                          '${entry.accountName} · '
                          '${entry.division ?? l10n.teamSportsNoDivision}',
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (entry.isManual) ...<Widget>[
                    AppBadge(label: l10n.teamSportsManualRecord),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  if (entry.hasRecord)
                    Text(
                      '${entry.wins}–${entry.losses}',
                      style: context.textStyles.titleMedium,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

