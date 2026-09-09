import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/invitations/presentation/widgets/invite_section.dart';
import 'package:fifa_queue/features/teams/domain/entities/team.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_membership.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_state.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/edit_team_sheet.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_duration.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_role_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeamSettingsPage extends StatelessWidget {
  const TeamSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<TeamsCubit, TeamsState>(
      builder: (context, state) {
        final selected = state.selectedTeam;

        return AppScaffold(
          appBar: AppAppBar(title: l10n.teamManageAction),
          body: selected == null
              ? const SizedBox.shrink()
              : _TeamSettingsBody(userTeam: selected, state: state),
        );
      },
    );
  }
}

class _TeamSettingsBody extends StatelessWidget {
  const _TeamSettingsBody({required this.userTeam, required this.state});

  final UserTeam userTeam;
  final TeamsState state;

  @override
  Widget build(BuildContext context) {
    final canManage = userTeam.canManageTeam;
    final team = userTeam.team;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      children: <Widget>[
        _InfoSection(team: team, canManage: canManage),
        const SizedBox(height: AppSpacing.lg),
        _VisibilitySection(team: team, canManage: canManage),
        const SizedBox(height: AppSpacing.lg),
        _DurationSection(team: team, canManage: canManage),
        const SizedBox(height: AppSpacing.lg),
        InviteSection(teamId: team.id, canManage: canManage),
        const SizedBox(height: AppSpacing.lg),
        _MembersSection(state: state),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.team, required this.canManage});

  final Team team;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                l10n.teamSettingsInfoTitle.toUpperCase(),
                style: context.textStyles.labelSmall,
              ),
              if (canManage)
                AppIconButton(
                  icon: Icons.edit_outlined,
                  tooltip: l10n.actionEdit,
                  onPressed: () => showEditTeamSheet(context, team),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(team.name, style: context.textStyles.titleMedium),
          if (team.tag != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            AppBadge(label: team.tag!),
          ],
        ],
      ),
    );
  }
}

class _VisibilitySection extends StatefulWidget {
  const _VisibilitySection({required this.team, required this.canManage});

  final Team team;
  final bool canManage;

  @override
  State<_VisibilitySection> createState() => _VisibilitySectionState();
}

class _VisibilitySectionState extends State<_VisibilitySection> {
  bool _isSaving = false;

  Future<void> _toggle(bool isPublic) async {
    if (_isSaving || isPublic == widget.team.isPublic) {
      return;
    }
    setState(() => _isSaving = true);
    context.read<TeamsCubit>().clearActionFailure();
    await context.read<TeamsCubit>().setTeamVisibility(
      teamId: widget.team.id,
      isPublic: isPublic,
    );
    if (mounted) {
      setState(() => _isSaving = false);
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
            l10n.teamVisibilitySectionTitle.toUpperCase(),
            style: context.textStyles.labelSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.team.isPublic
                ? l10n.teamVisibilityPublicHint
                : l10n.teamVisibilityPrivateHint,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: <Widget>[
              AppChip(
                label: l10n.teamVisibilityPublic,
                icon: Icons.public,
                isSelected: widget.team.isPublic,
                onPressed: widget.canManage && !_isSaving
                    ? () => _toggle(true)
                    : null,
              ),
              AppChip(
                label: l10n.teamVisibilityPrivate,
                icon: Icons.lock_outline,
                isSelected: !widget.team.isPublic,
                onPressed: widget.canManage && !_isSaving
                    ? () => _toggle(false)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DurationSection extends StatefulWidget {
  const _DurationSection({required this.team, required this.canManage});

  final Team team;
  final bool canManage;

  @override
  State<_DurationSection> createState() => _DurationSectionState();
}

class _DurationSectionState extends State<_DurationSection> {
  bool _isSaving = false;

  Future<void> _select(int seconds) async {
    if (_isSaving || seconds == widget.team.defaultSearchDuration.inSeconds) {
      return;
    }
    setState(() => _isSaving = true);
    context.read<TeamsCubit>().clearActionFailure();
    await context.read<TeamsCubit>().updateSearchDuration(
      teamId: widget.team.id,
      duration: Duration(seconds: seconds),
    );
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentSeconds = widget.team.defaultSearchDuration.inSeconds;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.teamSearchDurationLabel.toUpperCase(),
            style: context.textStyles.labelSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.canManage
                ? l10n.teamSearchDurationHelper
                : l10n.teamSearchDurationReadOnlyHelper,
            style: context.textStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final option in TeamDurationOptions.values)
                AppChip(
                  label: teamDurationLabel(l10n, option),
                  isSelected: currentSeconds == option,
                  onPressed: widget.canManage && !_isSaving
                      ? () => _select(option)
                      : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MembersSection extends StatelessWidget {
  const _MembersSection({required this.state});

  final TeamsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentUserId = context.read<AuthCubit>().state.user?.id;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                l10n.teamMembersTitle.toUpperCase(),
                style: context.textStyles.labelSmall,
              ),
              Text(
                l10n.teamMembersCount(state.members.length),
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (state.membersStatus == TeamMembersStatus.loading)
            const SizedBox(height: 72, child: AppLoading.inline())
          else
            for (final member in state.members)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: <Widget>[
                    AppAvatar(
                      label: member.displayName,
                      imageUrl: member.profile.avatarUrl,
                      size: AppSizing.avatarMd,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              member.displayName,
                              overflow: TextOverflow.ellipsis,
                              style: context.textStyles.bodyLarge,
                            ),
                          ),
                          if (member.userId == currentUserId) ...<Widget>[
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '· ${l10n.teamYou}',
                              style: context.textStyles.bodySmall?.copyWith(
                                color: context.colors.textTertiary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppBadge(
                      label: member.role.label(l10n),
                      tone: member.role.badgeTone,
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
