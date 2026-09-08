import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_state.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/rename_fc_account_sheet.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/rivals_division_l10n.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/rivals_division_picker_sheet.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/weekend_league_manual_record_sheet.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_event.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_membership.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    children: <Widget>[
      _DivisionSection(account: account),
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

class _DivisionSection extends StatelessWidget {
  const _DivisionSection({required this.account});

  final FcAccount account;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppCard(
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
                  account.rivalsDivision?.label(l10n) ??
                      l10n.fcAccountDivisionNone,
                  style: context.textStyles.titleMedium,
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
        ],
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

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.fcAccountWeekendLeagueTitle.toUpperCase(),
            style: context.textStyles.labelSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${record.$1}–${record.$2}',
            style: context.textStyles.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            account.hasWeekendLeagueManualOverride
                ? l10n.fcAccountWeekendLeagueManualLabel(record.$1, record.$2)
                : l10n.fcAccountWeekendLeagueComputedLabel(
                    record.$1,
                    record.$2,
                  ),
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton.secondary(
            label: l10n.fcAccountWeekendLeagueEditAction,
            icon: Icons.edit_outlined,
            onPressed: () => showWeekendLeagueManualRecordSheet(
              context: context,
              account: account,
            ),
          ),
        ],
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

  Future<void> _confirmArchive(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<FcAccountsCubit>();
    final navigator = Navigator.of(context);
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: l10n.fcAccountArchiveConfirmTitle,
        message: l10n.fcAccountArchiveConfirmMessage,
        confirmLabel: l10n.fcAccountArchiveAction,
        cancelLabel: l10n.actionCancel,
        isDestructive: true,
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        onCancel: () => Navigator.of(dialogContext).pop(false),
      ),
    );
    if (confirmed == true) {
      final ok = await cubit.archiveAccount(account.id);
      if (ok && navigator.canPop()) {
        navigator.pop();
      }
    }
  }

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
            label: l10n.fcAccountArchiveAction,
            icon: Icons.archive_outlined,
            onPressed: () => _confirmArchive(context),
          ),
        ],
      ),
    );
  }
}
