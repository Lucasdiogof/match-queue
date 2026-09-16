import 'dart:async';

import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/profiles/domain/entities/profile.dart';
import 'package:fifa_queue/features/profiles/presentation/pages/rivals_detail_page.dart';
import 'package:fifa_queue/features/profiles/presentation/pages/weekend_league_detail_page.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/squads_section.dart';
import 'package:fifa_queue/features/profiles/presentation/cubit/profiles_cubit.dart';
import 'package:fifa_queue/features/profiles/presentation/cubit/profiles_state.dart';
import 'package:fifa_queue/features/profiles/presentation/widgets/archive_profile_sheet.dart';
import 'package:fifa_queue/features/profiles/presentation/widgets/profile_avatar_picker.dart';
import 'package:fifa_queue/features/profiles/presentation/widgets/profile_platform_picker_sheet.dart';
import 'package:fifa_queue/features/profiles/presentation/widgets/rename_profile_sheet.dart';
import 'package:fifa_queue/features/profiles/presentation/widgets/rivals_division_l10n.dart';
import 'package:fifa_queue/features/game/presentation/widgets/competitive_mode_card.dart';
import 'package:fifa_queue/features/profiles/presentation/widgets/rivals_division_picker_sheet.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_event.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_rank.dart';
import 'package:fifa_queue/features/game/presentation/widgets/weekend_league_rank_l10n.dart';
import 'package:fifa_queue/features/game/presentation/widgets/debounced_win_loss_counter.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_membership.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_avatar.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProfileDetailPage extends StatelessWidget {
  const ProfileDetailPage({required this.profileId, super.key});

  final String profileId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<ProfilesCubit, ProfilesState>(
      builder: (context, state) {
        Profile? profile;
        for (final candidate in state.profiles) {
          if (candidate.id == profileId) {
            profile = candidate;
          }
        }
        return AppScaffold(
          appBar: AppAppBar(title: profile?.name ?? l10n.profilesPageTitle),
          body: profile == null
              ? const SizedBox.shrink()
              : _ProfileDetailBody(profile: profile, state: state),
        );
      },
    );
  }
}

class _ProfileDetailBody extends StatelessWidget {
  const _ProfileDetailBody({required this.profile, required this.state});

  final Profile profile;
  final ProfilesState state;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
    // Ordem: o que a conta E (elenco), como ela vai (Rivals, Champions),
    // times vinculados e so entao configuracoes da conta.
    children: <Widget>[
      _AccountAvatarCard(profile: profile, state: state),
      const SizedBox(height: AppSpacing.lg),
      SquadsSection(profileId: profile.id),
      const SizedBox(height: AppSpacing.lg),
      _RivalsSection(profile: profile),
      const SizedBox(height: AppSpacing.lg),
      _WeekendLeagueSection(
        profile: profile,
        weekendLeagueEvent: state.weekendLeagueEvent,
      ),
      const SizedBox(height: AppSpacing.lg),
      _LinkedTeamsSection(profile: profile),
      const SizedBox(height: AppSpacing.lg),
      _SettingsSection(profile: profile),
    ],
  );
}

class _AccountAvatarCard extends StatelessWidget {
  const _AccountAvatarCard({required this.profile, required this.state});

  final Profile profile;
  final ProfilesState state;

  @override
  Widget build(BuildContext context) => AppCard(
    child: ProfileAvatarPicker(
      profileId: profile.id,
      isSaving: state.isSaving,
      hasAvatar: profile.avatarUrl != null,
      preview: AppAvatar(
        label: profile.name,
        imageUrl: profile.avatarUrl,
        size: AppSizing.avatarXl,
      ),
    ),
  );
}

/// Divisão + placar num card só: eram dois antes (um pra divisão, outro pra
/// vitórias/derrotas), o que lia como duas seções de assuntos diferentes
/// quando é a mesma coisa -- como a Conta está indo em Rivals.
class _RivalsSection extends StatelessWidget {
  const _RivalsSection({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<ProfilesCubit>();

    return CompetitiveModeCard(
      mode: CompetitiveMode.rivals,
      title: l10n.rivalsSectionTitle,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RivalsDetailPage(profile: profile),
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
                      profile.rivalsDivision?.label(l10n) ??
                          l10n.profileDivisionNone,
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
                      profileId: profile.id,
                      selected: profile.rivalsDivision,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              DebouncedWinLossCounter(
                wins: profile.rivalsWins,
                losses: profile.rivalsLosses,
                winsLabel: l10n.statsWinsLabel,
                lossesLabel: l10n.statsLossesLabel,
                addWinTooltip: l10n.recordAddWinTooltip,
                addLossTooltip: l10n.recordAddLossTooltip,
                removeWinTooltip: l10n.recordRemoveWinTooltip,
                removeLossTooltip: l10n.recordRemoveLossTooltip,
                onFlush: (wd, ld) async {
                  final ok = await cubit.incrementRivalsRecord(
                    profileId: profile.id,
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
    required this.profile,
    required this.weekendLeagueEvent,
  });

  final Profile profile;
  final WeekendLeagueEvent? weekendLeagueEvent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (weekendLeagueEvent == null) {
      return const SizedBox.shrink();
    }
    final record = profile.weekendLeagueRecord;
    final rank = WeekendLeagueRank.fromWins(record.$1);
    final cubit = context.read<ProfilesCubit>();

    return CompetitiveModeCard(
      mode: CompetitiveMode.champions,
      title: l10n.profileWeekendLeagueTitle,
      trailing: rank == null ? null : AppBadge(label: rank.label),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WeekendLeagueDetailPage(
            profile: profile,
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
              profileId: profile.id,
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
  const _LinkedTeamsSection({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final teams = context.watch<TeamsCubit>().state.teams;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.profileLinkedTeamsTitle.toUpperCase(),
            style: context.textStyles.labelSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          if (teams.isEmpty)
            Text(
              l10n.profileLinkedTeamsEmpty,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            )
          else
            for (var i = 0; i < teams.length; i++) ...<Widget>[
              if (i > 0) const AppDivider(),
              _TeamLinkRow(profile: profile, userTeam: teams[i]),
            ],
        ],
      ),
    );
  }
}

class _TeamLinkRow extends StatelessWidget {
  const _TeamLinkRow({required this.profile, required this.userTeam});

  final Profile profile;
  final UserTeam userTeam;

  Future<void> _unlink(BuildContext context) async {
    final l10n = context.l10n;
    final fcCubit = context.read<ProfilesCubit>();
    final confirmed = await showAppBottomSheet<bool>(
      context: context,
      builder: (sheetContext) => AppBottomSheet(
        title: l10n.profileLeaveTeamConfirmTitle,
        subtitle: l10n.profileLeaveTeamConfirmMessage(userTeam.team.name),
        actions: <Widget>[
          AppButton.danger(
            label: l10n.profileUnlinkTeamAction,
            expanded: true,
            onPressed: () => Navigator.of(sheetContext).pop(true),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.ghost(
            label: l10n.actionCancel,
            expanded: true,
            onPressed: () => Navigator.of(sheetContext).pop(false),
          ),
        ],
        child: const SizedBox.shrink(),
      ),
    );
    if (confirmed == true) {
      unawaited(
        fcCubit.unlinkFromTeam(profileId: profile.id, teamId: userTeam.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLinked = profile.isLinkedTo(userTeam.id);
    final fcCubit = context.read<ProfilesCubit>();
    final isSaving = context.watch<ProfilesCubit>().state.isSaving;
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          TeamAvatar(team: userTeam.team, size: AppSizing.avatarMd),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  userTeam.team.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodyLarge,
                ),
                if (userTeam.team.tag != null)
                  Text(
                    userTeam.team.tag!,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppButton.ghost(
            label: isLinked
                ? context.l10n.profileUnlinkTeamAction
                : context.l10n.profileLinkTeamAction,
            isLoading: isSaving,
            onPressed: isSaving
                ? null
                : () => isLinked
                      ? _unlink(context)
                      : fcCubit.linkToTeam(
                          profileId: profile.id,
                          teamId: userTeam.id,
                        ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.profileSettingsTitle.toUpperCase(),
            style: context.textStyles.labelSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton.secondary(
            label: l10n.profileRenameAction,
            icon: Icons.edit_outlined,
            onPressed: () => showRenameProfileSheet(
              context: context,
              profileId: profile.id,
              currentName: profile.name,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.secondary(
            label: l10n.profilePlatformSettingsAction(
              profile.platform?.displayLabel ?? l10n.profilePlatformNone,
            ),
            icon: Icons.videogame_asset_outlined,
            onPressed: () => showProfilePlatformPickerSheet(
              context: context,
              profileId: profile.id,
              selected: profile.platform,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.secondary(
            label: l10n.navHistory,
            icon: Icons.history_outlined,
            onPressed: () =>
                context.push(AppRoutes.profileHistoryLocation(profile.id)),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.secondary(
            label: l10n.notificationsSectionTitle,
            icon: Icons.notifications_outlined,
            onPressed: () => context.push(AppRoutes.accountNotifications.path),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.secondary(
            label: l10n.profileSharingAction,
            icon: Icons.lock_outline,
            onPressed: () =>
                context.push(AppRoutes.profileSharingLocation(profile.id)),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton.danger(
            label: l10n.profileArchiveAction,
            icon: Icons.delete_outline,
            onPressed: () async {
              final navigator = Navigator.of(context);
              final archived = await showArchiveProfileSheet(
                context: context,
                profileId: profile.id,
                profileName: profile.name,
              );
              // A conta some de state.profiles assim que arquivada: esta
              // tela nao tem mais nada pra mostrar, entao volta sozinha em
              // vez de deixar a pessoa olhando pra uma tela vazia.
              if (archived && navigator.canPop()) {
                navigator.pop();
              }
            },
          ),
        ],
      ),
    );
  }
}
