import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account_stats.dart';
import 'package:fifa_queue/features/fc_accounts/domain/repositories/fc_account_repository.dart';
import 'package:fifa_queue/features/game/domain/entities/player_leaderboard_entry.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_state.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/rivals_division_l10n.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/rivals_division_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Detalhe de Division Rivals de uma conta -- all-time nesta etapa (sem
/// season/semana modelada ainda, simplificacao consciente).
class RivalsDetailPage extends StatefulWidget {
  const RivalsDetailPage({required this.account, super.key});

  final FcAccount account;

  @override
  State<RivalsDetailPage> createState() => _RivalsDetailPageState();
}

class _RivalsDetailPageState extends State<RivalsDetailPage> {
  late Future<RivalsAccountStats> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = getIt<FcAccountRepository>().fetchRivalsAccountStats(
      widget.account.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: AppAppBar(title: l10n.rivalsDetailTitle),
      body: FutureBuilder<RivalsAccountStats>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoading();
          }
          final error = snapshot.error;
          if (error != null) {
            return AppErrorState(
              title: l10n.errorUnexpected,
              message: error is AppFailure
                  ? error.localizedMessage(l10n)
                  : l10n.errorUnexpected,
              retryLabel: l10n.actionRetry,
              onRetry: () => setState(_load),
            );
          }
          final stats = snapshot.data;
          if (stats == null) {
            return const SizedBox.shrink();
          }
          return _Body(accountId: widget.account.id, stats: stats);
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.accountId, required this.stats});

  final String accountId;
  final RivalsAccountStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final aggregate = stats.aggregate;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      children: <Widget>[
        _DivisionSection(accountId: accountId),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          variant: AppCardVariant.elevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${aggregate.wins}–${aggregate.losses}',
                style: context.textStyles.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _StatTile(
                      label: l10n.statsMatchesLabel,
                      value: '${aggregate.matchesCount}',
                    ),
                  ),
                  Expanded(
                    child: _StatTile(
                      label: l10n.statsGoalsLabel,
                      value: '${aggregate.goalsFor}',
                    ),
                  ),
                  Expanded(
                    child: _StatTile(
                      label: l10n.statsGoalDiffLabel,
                      value: '${aggregate.goalDiff}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.rivalsAllTimeNote,
                style: context.textStyles.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _LeaderboardCard(
          title: l10n.statsTopScorersTitle,
          entries: stats.topScorers,
          showGoals: true,
        ),
        const SizedBox(height: AppSpacing.lg),
        _LeaderboardCard(
          title: l10n.statsTopAssistsTitle,
          entries: stats.topAssists,
          showGoals: false,
        ),
      ],
    );
  }
}

/// A divisao e o dado principal de Rivals, entao vive aqui e nao so na tela
/// da Conta: o card da Home diz "divisao nao informada" e traz o usuario pra
/// ca -- chegar sem poder informar era um beco sem saida. Reusa o mesmo
/// picker da Conta FC, nunca uma segunda forma de escrever o campo.
class _DivisionSection extends StatelessWidget {
  const _DivisionSection({required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<FcAccountsCubit, FcAccountsState>(
        builder: (context, state) {
          final l10n = context.l10n;
          FcAccount? account;
          for (final candidate in state.accounts) {
            if (candidate.id == accountId) {
              account = candidate;
            }
          }
          final division = account?.rivalsDivision;

          return AppCard(
            variant: AppCardVariant.elevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.fcAccountDivisionTitle.toUpperCase(),
                  style: context.textStyles.labelSmall,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        division?.label(l10n) ?? l10n.fcAccountDivisionNone,
                        style: context.textStyles.titleMedium?.copyWith(
                          color: division == null
                              ? context.colors.textSecondary
                              : context.colors.textPrimary,
                        ),
                      ),
                    ),
                    if (account != null)
                      AppButton.ghost(
                        label: division == null
                            ? l10n.rivalsSetDivisionAction
                            : l10n.actionEdit,
                        onPressed: () => showRivalsDivisionPickerSheet(
                          context: context,
                          accountId: accountId,
                          selected: division,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      );
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      Text(value, style: context.textStyles.titleMedium),
      const SizedBox(height: AppSpacing.xxs),
      Text(
        label,
        style: context.textStyles.labelSmall?.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    ],
  );
}

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({
    required this.title,
    required this.entries,
    required this.showGoals,
  });

  final String title;
  final List<PlayerLeaderboardEntry> entries;
  final bool showGoals;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title.toUpperCase(), style: context.textStyles.labelSmall),
          const SizedBox(height: AppSpacing.md),
          if (entries.isEmpty)
            Text(
              showGoals
                  ? l10n.statsEmptyScorersMessage
                  : l10n.statsEmptyAssistsMessage,
              style: context.textStyles.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            )
          else
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        entry.playerName,
                        style: context.textStyles.bodyMedium,
                      ),
                    ),
                    Text(
                      showGoals ? '${entry.goals}' : '${entry.assists}',
                      style: context.textStyles.titleSmall,
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
