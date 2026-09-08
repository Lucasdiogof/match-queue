import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_sports_dashboard.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/team_sports_cubit.dart';
import 'package:fifa_queue/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

class TeamSportsRankingSection extends StatelessWidget {
  const TeamSportsRankingSection({
    required this.ranking,
    required this.minRankedMatches,
    required this.onMemberTap,
    super.key,
  });

  final List<TeamMemberSportsStats> ranking;
  final int minRankedMatches;
  final void Function(TeamMemberSportsStats member) onMemberTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.teamSportsRankingTitle.toUpperCase(),
            style: context.textStyles.labelSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < ranking.length; i++)
            _RankingRow(
              position: i + 1,
              member: ranking[i],
              onTap: () => onMemberTap(ranking[i]),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.teamSportsMinSampleHint(minRankedMatches),
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.position,
    required this.member,
    required this.onTap,
  });

  final int position;
  final TeamMemberSportsStats member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    // Destaque discreto para o pódio; sem sistema de badges (itens 61/62).
    final isPodium = position <= 3 && member.isRanked;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 26,
              child: Text(
                '$position',
                style: context.textStyles.bodyMedium?.copyWith(
                  color: isPodium ? colors.textPrimary : colors.textTertiary,
                  fontWeight: isPodium ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            AppAvatar(
              label: member.displayName,
              imageUrl: member.avatarUrl,
              size: AppSizing.avatarSm,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          member.displayName,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.bodyLarge,
                        ),
                      ),
                      if (member.hasMultipleAccounts) ...<Widget>[
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          l10n.teamSportsAccountsCount(member.accountsCount),
                          style: context.textStyles.bodySmall?.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    member.hasMatches
                        ? l10n.teamSportsRecordLine(
                            member.matches,
                            member.wins,
                            member.losses,
                          )
                        : l10n.teamSportsNoMatchesMember,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  formatWinRate(context, member.winRate),
                  style: context.textStyles.titleMedium,
                ),
                // Quem tem poucos jogos aparece igual, apenas marcado —
                // nunca escondido (itens 14/45).
                if (member.hasMatches && !member.isRanked)
                  Text(
                    l10n.teamSportsSmallSample,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: colors.warning,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TeamPlayerLeaderboardSection extends StatelessWidget {
  const TeamPlayerLeaderboardSection({
    required this.entries,
    required this.byAssists,
    super.key,
  });

  final List<TeamPlayerLeaderboardEntry> entries;
  final bool byAssists;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                (byAssists
                        ? l10n.teamSportsAssistsTitle
                        : l10n.teamSportsScorersTitle)
                    .toUpperCase(),
                style: context.textStyles.labelSmall,
              ),
              if (entries.length >= 10)
                InkWell(
                  onTap: () => _showFull(context),
                  child: Text(
                    l10n.teamSportsSeeAll,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (entries.isEmpty)
            Text(
              byAssists
                  ? l10n.teamSportsNoAssistsYet
                  : l10n.teamSportsNoScorersYet,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            )
          else
            for (var i = 0; i < entries.length; i++)
              _LeaderboardRow(
                position: i + 1,
                entry: entries[i],
                byAssists: byAssists,
              ),
        ],
      ),
    );
  }

  Future<void> _showFull(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<TeamSportsCubit>();
    final full = await cubit.fullLeaderboard(byAssists: byAssists);
    if (!context.mounted) {
      return;
    }
    await showAppBottomSheet<void>(
      context: context,
      builder: (sheetContext) => AppBottomSheet(
        title: byAssists
            ? l10n.teamSportsAssistsTitle
            : l10n.teamSportsScorersTitle,
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.6,
          child: ListView.builder(
            itemCount: full.length,
            itemBuilder: (context, index) => _LeaderboardRow(
              position: index + 1,
              entry: full[index],
              byAssists: byAssists,
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.position,
    required this.entry,
    required this.byAssists,
  });

  final int position;
  final TeamPlayerLeaderboardEntry entry;
  final bool byAssists;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final value = byAssists ? entry.assists : entry.goals;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 26,
            child: Text(
              '$position',
              style: context.textStyles.bodyMedium?.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ),
          // Sem arte de carta: placeholder próprio, nunca bloqueia a lista
          // (item 77).
          AppAvatar(label: entry.playerName, size: AppSizing.avatarSm),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  entry.playerName,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodyLarge,
                ),
                // O gol tem dono: sempre o membro e a Conta (item 25).
                Text(
                  '${entry.displayName} · ${entry.accountName}',
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('$value', style: context.textStyles.titleMedium),
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
        .where((e) => e.matches > 0 || e.division != null)
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
                  if (entry.matches > 0) ...<Widget>[
                    Text(
                      l10n.teamSportsRecordLine(
                        entry.matches,
                        entry.wins,
                        entry.losses,
                      ),
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      formatWinRate(context, entry.winRate),
                      style: context.textStyles.titleMedium,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class TeamSportsActivitySection extends StatelessWidget {
  const TeamSportsActivitySection({required this.activity, super.key});

  final List<TeamSportsActivity> activity;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.teamSportsActivityTitle.toUpperCase(),
            style: context.textStyles.labelSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          if (activity.isEmpty)
            Text(
              l10n.teamSportsNoActivityYet,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            )
          else
            for (final event in activity)
              _ActivityRow(event: event, l10n: l10n),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.event, required this.l10n});

  final TeamSportsActivity event;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final when = DateFormat.MMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).add_Hm().format(event.occurredAt.toLocal());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppAvatar(
            label: event.displayName,
            imageUrl: event.avatarUrl,
            size: AppSizing.avatarSm,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: event.displayName,
                        style: context.textStyles.bodyLarge,
                      ),
                      TextSpan(text: ' ', style: context.textStyles.bodyMedium),
                      TextSpan(
                        text: event.isWin
                            ? l10n.teamSportsActivityWin
                            : l10n.teamSportsActivityLoss,
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: event.isWin
                              ? colors.success
                              : colors.textSecondary,
                        ),
                      ),
                      if (event.hasScore)
                        TextSpan(
                          text: ' ${event.goalsFor}–${event.goalsAgainst}',
                          style: context.textStyles.bodyMedium,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  <String>[
                    event.accountName,
                    when,
                    if (event.topScorerName != null &&
                        (event.topScorerGoals ?? 0) > 0)
                      '${event.topScorerName} '
                          '${l10n.teamSportsGoalsShort(event.topScorerGoals!)}',
                  ].join(' · '),
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
