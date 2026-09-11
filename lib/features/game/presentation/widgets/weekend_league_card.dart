import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account_stats.dart';
import 'package:fifa_queue/features/fc_accounts/domain/repositories/fc_account_repository.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_state.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/pages/weekend_league_detail_page.dart';
import 'package:fifa_queue/features/game/domain/entities/player_leaderboard_entry.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_event.dart';
import 'package:fifa_queue/features/game/presentation/widgets/competitive_mode_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Contextual ao Elenco selecionado (Etapa 9) -- o record mostrado troca
/// junto com o elenco, nunca é agregado entre elencos.
class WeekendLeagueCard extends StatelessWidget {
  const WeekendLeagueCard({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<FcAccountsCubit, FcAccountsState>(
        buildWhen: (previous, current) =>
            previous.weekendLeagueEvent != current.weekendLeagueEvent ||
            previous.selectedAccount != current.selectedAccount,
        builder: (context, state) {
          final event = state.weekendLeagueEvent;
          final account = state.selectedAccount;
          if (event == null || account == null) {
            return const SizedBox.shrink();
          }
          return _WeekendLeagueCardBody(event: event, account: account);
        },
      );
}

class _WeekendLeagueCardBody extends StatelessWidget {
  const _WeekendLeagueCardBody({required this.event, required this.account});

  final WeekendLeagueEvent event;
  final FcAccount account;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final record = account.weekendLeagueRecord;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: CompetitiveModeCard(
        mode: CompetitiveMode.champions,
        title: l10n.gameModeWeekendLeague,
        trailing: event.isActive
            ? Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.championsGold,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                WeekendLeagueDetailPage(account: account, event: event),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                CompetitiveStat(
                  value: '${record.$1}',
                  label: l10n.statsWinsLabel,
                ),
                const SizedBox(width: AppSpacing.xl),
                CompetitiveStat(
                  value: '${record.$2}',
                  label: l10n.statsLossesLabel,
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right,
                  size: AppSizing.iconMd,
                  color: AppColors.championsGold,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              account.hasWeekendLeagueManualOverride
                  ? l10n.weekendLeagueBadge(event.number)
                  : '${l10n.weekendLeagueBadge(event.number)} · '
                        '${l10n.weekendLeagueWindow(l10n.historyEntryDate(event.startsAt), l10n.historyEntryDate(event.endsAt))}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.bodySmall?.copyWith(
                color: AppColors.darkTextSecondary,
              ),
            ),
            FutureBuilder<WeekendLeagueAccountStats>(
              future: getIt<FcAccountRepository>()
                  .fetchWeekendLeagueAccountStats(
                    accountId: account.id,
                    eventId: event.id,
                  ),
              builder: (context, snapshot) {
                final scorers =
                    snapshot.data?.topScorers ??
                    const <PlayerLeaderboardEntry>[];
                if (scorers.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    l10n.statsTopScorerInlineLabel(
                      scorers.first.playerName,
                      scorers.first.goals,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
