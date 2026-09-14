import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/pages/rivals_detail_page.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/pages/weekend_league_detail_page.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/squads_section.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_state.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/rename_fc_account_sheet.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/rivals_division_l10n.dart';
import 'package:fifa_queue/features/game/presentation/widgets/competitive_mode_card.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/rivals_division_picker_sheet.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_event.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_rank.dart';
import 'package:fifa_queue/features/game/presentation/widgets/weekend_league_rank_l10n.dart';
import 'package:fifa_queue/features/game/presentation/widgets/debounced_win_loss_counter.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_membership.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class FcAccountDetailPage extends StatelessWidget {
  const FcAccountDetailPage({required this.fcAccountId, super.key});

  final String fcAccountId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<FcAccountsCubit, FcAccountsState>(
      builder: (context, state) {
        FcAccount? account;
        for (final candidate in state.accounts) {
          if (candidate.id == fcAccountId) {
            account = candidate;
          }
        }
        return AppScaffold(
          appBar: AppAppBar(title: account?.name ?? l10n.fcAccountsPageTitle),
          body: account == null
              ? const SizedBox.shrink()
              : _FcAccountDetailBody(account: account, state: state),
        );
      },
    );
  }
}

class _FcAccountDetailBody extends StatelessWidget {
  const _FcAccountDetailBody({required this.account, required this.state});

  final FcAccount account;
  final FcAccountsState state;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
    // Ordem: o que a conta E (elenco), como ela vai (Rivals, Champions),
    // times vinculados e so entao configuracoes da conta.
    children: <Widget>[
      SquadsSection(fcAccountId: account.id),
      const SizedBox(height: AppSpacing.lg),
      _RivalsSection(account: account),
      const SizedBox(height: AppSpacing.lg),
      _WeekendLeagueSection(
        account: account,
        weekendLeagueEvent: state.weekendLeagueEvent,
      ),
      const SizedBox(height: AppSpacing.lg),
      _LinkedTeamsSection(account: account),
      const SizedBox(height: AppSpacing.lg),
      _SettingsSection(account: account),
    ],
  );
}

/// Divisão + placar num card só: eram dois antes (um pra divisão, outro pra
/// vitórias/derrotas), o que lia como duas seções de assuntos diferentes
/// quando é a mesma coisa -- como a Conta está indo em Rivals.
class _RivalsSection extends StatelessWidget {
  const _RivalsSection({required this.account});

  final FcAccount account;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<FcAccountsCubit>();

    return CompetitiveModeCard(
      mode: CompetitiveMode.rivals,
      title: l10n.rivalsSectionTitle,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RivalsDetailPage(account: account),
        ),
      ),
      // Tema escuro pro subtree inteiro: o contador (+/- de vitorias e
      // derrotas) usa context.colors/textStyles pra pintar botao e texto, e
      // esses so viram claro-sobre-escuro se o Theme ambiente for o dark --
      // o merge de DefaultTextStyle/IconTheme do CompetitiveModeCard nao
      // alcanca widgets que leem cor direto do tema (AppIconButton).
      child: Theme(
        data: AppTheme.dark,
        child: Builder(
          builder: (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      account.rivalsDivision?.label(l10n) ??
                          l10n.fcAccountDivisionNone,
                      style: context.textStyles.titleMedium?.copyWith(
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                  ),
                  AppIconButton(
                    icon: Icons.edit_outlined,
                    tooltip: l10n.actionEdit,
                    onPressed: () => showRivalsDivisionPickerSheet(
                      context: context,
                      accountId: account.id,
                      selected: account.rivalsDivision,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              DebouncedWinLossCounter(
                wins: account.rivalsWins,
                losses: account.rivalsLosses,
                winsLabel: l10n.statsWinsLabel,
                lossesLabel: l10n.statsLossesLabel,
                addWinTooltip: l10n.recordAddWinTooltip,
                addLossTooltip: l10n.recordAddLossTooltip,
                removeWinTooltip: l10n.recordRemoveWinTooltip,
                removeLossTooltip: l10n.recordRemoveLossTooltip,
                onFlush: (wd, ld) async {
                  final ok = await cubit.incrementRivalsRecord(
                    accountId: account.id,
                    winDelta: wd,
                    lossDelta: ld,
                  );
                  if (ok) return null;
                  final failure = cubit.state.actionFailure;
                  cubit.clearActionFailure();
                  return failure?.localizedMessage(l10n) ??
                      l10n.errorUnexpected;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekendLeagueSection extends StatelessWidget {
  const _WeekendLeagueSection({
    required this.account,
    required this.weekendLeagueEvent,
  });

  final FcAccount account;
  final WeekendLeagueEvent? weekendLeagueEvent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (weekendLeagueEvent == null) {
      return const SizedBox.shrink();
    }
    final record = account.weekendLeagueRecord;
    final rank = WeekendLeagueRank.fromWins(record.$1);
    final cubit = context.read<FcAccountsCubit>();

    return CompetitiveModeCard(
      mode: CompetitiveMode.champions,
      title: l10n.fcAccountWeekendLeagueTitle,
      trailing: rank == null ? null : AppBadge(label: rank.label),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WeekendLeagueDetailPage(
            account: account,
            event: weekendLeagueEvent!,
          ),
        ),
      ),
      // Ver comentario da mesma tecnica em _RivalsSection.
      child: Theme(
        data: AppTheme.dark,
        child: DebouncedWinLossCounter(
          wins: record.$1,
          losses: record.$2,
          winsLabel: l10n.statsWinsLabel,
          lossesLabel: l10n.statsLossesLabel,
          addWinTooltip: l10n.recordAddWinTooltip,
          addLossTooltip: l10n.recordAddLossTooltip,
          removeWinTooltip: l10n.recordRemoveWinTooltip,
          removeLossTooltip: l10n.recordRemoveLossTooltip,
          onFlush: (wd, ld) async {
            final ok = await cubit.incrementWeekendLeagueRecord(
              accountId: account.id,
              winDelta: wd,
              lossDelta: ld,
            );
            if (ok) return null;
            final failure = cubit.state.actionFailure;
            cubit.clearActionFailure();
            return failure?.localizedMessage(l10n) ?? l10n.errorUnexpected;
          },
        ),
      ),
    );
  }
}

class _LinkedTeamsSection extends StatelessWidget {
  const _LinkedTeamsSection({required this.account});

  final FcAccount account;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final teams = context.watch<TeamsCubit>().state.teams;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.fcAccountLinkedTeamsTitle.toUpperCase(),
            style: context.textStyles.labelSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          if (teams.isEmpty)
            Text(
              l10n.fcAccountLinkedTeamsEmpty,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            )
          else
            for (final userTeam in teams)
              _TeamLinkRow(account: account, userTeam: userTeam),
        ],
      ),
    );
  }
}

class _TeamLinkRow extends StatelessWidget {
  const _TeamLinkRow({required this.account, required this.userTeam});

  final FcAccount account;
  final UserTeam userTeam;

  @override
  Widget build(BuildContext context) {
    final isLinked = account.isLinkedTo(userTeam.id);
    final fcCubit = context.read<FcAccountsCubit>();
    final isSaving = context.watch<FcAccountsCubit>().state.isSaving;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              userTeam.team.name,
              style: context.textStyles.bodyLarge,
            ),
          ),
          AppButton.ghost(
            label: isLinked
                ? context.l10n.fcAccountUnlinkTeamAction
                : context.l10n.fcAccountLinkTeamAction,
            isLoading: isSaving,
            onPressed: isSaving
                ? null
                : () => isLinked
                      ? fcCubit.unlinkFromTeam(
                          accountId: account.id,
                          teamId: userTeam.id,
                        )
                      : fcCubit.linkToTeam(
                          accountId: account.id,
                          teamId: userTeam.id,
                        ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.account});

  final FcAccount account;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.fcAccountSettingsTitle.toUpperCase(),
            style: context.textStyles.labelSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton.secondary(
            label: l10n.fcAccountRenameAction,
            icon: Icons.edit_outlined,
            onPressed: () => showRenameFcAccountSheet(
              context: context,
              accountId: account.id,
              currentName: account.name,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.secondary(
            label: l10n.navHistory,
            icon: Icons.history_outlined,
            onPressed: () =>
                context.push(AppRoutes.fcAccountHistoryLocation(account.id)),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.secondary(
            label: l10n.publicProfileSectionTitle,
            icon: Icons.lock_outline,
            onPressed: () =>
                context.push(AppRoutes.profileSharingLocation(account.id)),
          ),
        ],
      ),
    );
  }
}
