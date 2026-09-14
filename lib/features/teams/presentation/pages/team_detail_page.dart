import 'dart:async';

import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/matchmaking/domain/repositories/matchmaking_repository.dart';
import 'package:fifa_queue/features/requests/domain/entities/requests_inbox.dart';
import 'package:fifa_queue/features/requests/domain/repositories/requests_repository.dart';
import 'package:fifa_queue/features/requests/presentation/cubit/requests_cubit.dart';
import 'package:fifa_queue/features/requests/presentation/cubit/requests_state.dart';
import 'package:fifa_queue/features/teams/domain/entities/team.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_member_status.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_membership.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_role.dart';
import 'package:fifa_queue/features/teams/domain/repositories/team_repository.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_sports_dashboard.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/team_sports_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/team_status_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/team_status_state.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_state.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/edit_team_sheet.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_avatar.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_role_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Detalhe do Time (Etapa 11, item 5): nome, tag, lista de jogadores,
/// status operacional. As configuracoes/engrenagem do time ficam AQUI, nao
/// mais na lista.
class TeamDetailPage extends StatelessWidget {
  const TeamDetailPage({required this.teamId, super.key});

  final String teamId;

  @override
  Widget build(BuildContext context) => BlocBuilder<TeamsCubit, TeamsState>(
    builder: (context, state) {
      final userTeam = _findTeam(state, teamId);

      return AppScaffold(
        appBar: AppAppBar(
          title: userTeam?.team.name ?? context.l10n.teamTitle,
          subtitle: userTeam?.team.tag,
          actions: <Widget>[
            if (userTeam != null && userTeam.canManageTeam)
              AppIconButton(
                icon: Icons.edit_outlined,
                tooltip: context.l10n.actionEdit,
                variant: AppIconButtonVariant.surface,
                onPressed: () => showEditTeamSheet(
                  context,
                  userTeam.team,
                  isOwner: userTeam.role.isOwner,
                ),
              ),
          ],
        ),
        body: userTeam == null
            ? const AppLoading()
            : MultiBlocProvider(
                key: ValueKey(teamId),
                providers: <BlocProvider<dynamic>>[
                  BlocProvider<TeamStatusCubit>(
                    create: (_) => TeamStatusCubit(
                      getIt<TeamRepository>(),
                      getIt<MatchmakingRepository>(),
                      teamId: teamId,
                    )..start(),
                  ),
                  // Dashboard esportivo so carrega ao ENTRAR no Time
                  // (item 50) -- a lista de Times continua leve.
                  BlocProvider<TeamSportsCubit>(
                    create: (_) =>
                        TeamSportsCubit(getIt<TeamRepository>(), teamId: teamId)
                          ..load(),
                  ),
                ],
                child: _TeamStatusBody(
                  team: userTeam.team,
                  viewerRole: userTeam.role,
                ),
              ),
      );
    },
  );

  UserTeam? _findTeam(TeamsState state, String teamId) {
    for (final userTeam in state.teams) {
      if (userTeam.id == teamId) {
        return userTeam;
      }
    }
    return null;
  }
}

class _TeamStatusBody extends StatelessWidget {
  const _TeamStatusBody({required this.team, required this.viewerRole});

  final Team team;
  final TeamRole viewerRole;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<TeamStatusCubit, TeamStatusState>(
        builder: (context, state) =>
            BlocBuilder<TeamSportsCubit, TeamSportsState>(
              builder: (context, sports) => RefreshIndicator(
                onRefresh: context.read<TeamSportsCubit>().refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  children: <Widget>[
                    _TeamHeaderCard(
                      team: team,
                      state: state,
                      dashboard: sports.dashboard,
                    ),
                    if (viewerRole.canManageTeam) ...<Widget>[
                      const SizedBox(height: AppSpacing.lg),
                      _InviteMemberButton(teamId: team.id),
                      const SizedBox(height: AppSpacing.lg),
                      _PendingRequestsSection(teamId: team.id),
                      const SizedBox(height: AppSpacing.lg),
                      _SentInvitationsSection(teamId: team.id),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    // Status operacional continua sendo do Realtime da Etapa
                    // anterior -- stats nunca se misturam com ele (item 46).
                    _MemberStatusSection(
                      teamId: team.id,
                      state: state,
                      viewerRole: viewerRole,
                    ),
                  ],
                ),
              ),
            ),
      );
}

class _TeamHeaderCard extends StatelessWidget {
  const _TeamHeaderCard({
    required this.team,
    required this.state,
    this.dashboard,
  });

  final Team team;
  final TeamStatusState state;
  final TeamSportsDashboard? dashboard;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return AppCard(
      variant: AppCardVariant.elevated,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TeamAvatar(team: team, size: AppSizing.avatarXl),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(team.name, style: context.textStyles.headlineSmall),
                if (team.tag != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  AppBadge(label: team.tag!),
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${l10n.teamMembersCount(state.members.length)} · '
                  '${l10n.teamActiveCount(state.activeCount)}',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                if (dashboard != null &&
                    dashboard!.summary.hasMatches) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    l10n.teamSportsMatchesCount(dashboard!.summary.matches),
                    style: context.textStyles.bodySmall?.copyWith(
                      color: colors.textTertiary,
                    ),
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

class _MemberStatusSection extends StatelessWidget {
  const _MemberStatusSection({
    required this.teamId,
    required this.state,
    required this.viewerRole,
  });

  final String teamId;
  final TeamStatusState state;
  final TeamRole viewerRole;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.teamDetailPlayersTitle.toUpperCase(),
            style: context.textStyles.labelSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          if (state.status == TeamStatusLoadStatus.loading)
            const SizedBox(height: 72, child: AppLoading.inline())
          else if (state.status == TeamStatusLoadStatus.failure)
            AppBanner(
              tone: AppBannerTone.danger,
              message:
                  state.failure?.localizedMessage(l10n) ?? l10n.errorUnexpected,
            )
          else
            for (final member in state.members)
              _MemberStatusRow(
                teamId: teamId,
                member: member,
                viewerRole: viewerRole,
              ),
        ],
      ),
    );
  }
}

class _MemberStatusRow extends StatelessWidget {
  const _MemberStatusRow({
    required this.teamId,
    required this.member,
    required this.viewerRole,
  });

  final String teamId;
  final TeamMemberStatus member;
  final TeamRole viewerRole;

  /// So OWNER mexe em cargo; OWNER e ADMIN removem, mas ADMIN so remove
  /// PLAYER -- a mesma matriz que o servidor ja valida em
  /// remove_team_member/set_team_member_role, aqui so pra decidir o que
  /// MOSTRAR (o servidor recusa de qualquer jeito se a UI errar).
  bool get _canShowMenu {
    if (member.role == TeamRole.owner) {
      return false;
    }
    if (viewerRole == TeamRole.owner) {
      return true;
    }
    return viewerRole == TeamRole.manager && member.role == TeamRole.player;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return InkWell(
      onTap: () =>
          context.push(AppRoutes.playerProfileLocation(teamId, member.userId)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: <Widget>[
            AppAvatar(
              label: member.displayName,
              imageUrl: member.avatarUrl,
              size: AppSizing.avatarMd,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                member.displayName,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.bodyLarge,
              ),
            ),
            AppBadge(
              label: member.role.label(l10n),
              tone: member.role.badgeTone,
            ),
            if (_canShowMenu)
              PopupMenuButton<_MemberAction>(
                icon: const Icon(Icons.more_vert),
                onSelected: (action) => _handle(context, action),
                itemBuilder: (context) => <PopupMenuEntry<_MemberAction>>[
                  if (viewerRole == TeamRole.owner &&
                      member.role == TeamRole.player)
                    PopupMenuItem<_MemberAction>(
                      value: _MemberAction.promote,
                      child: Text(l10n.teamMemberPromoteAction),
                    ),
                  if (viewerRole == TeamRole.owner &&
                      member.role == TeamRole.manager)
                    PopupMenuItem<_MemberAction>(
                      value: _MemberAction.demote,
                      child: Text(l10n.teamMemberDemoteAction),
                    ),
                  PopupMenuItem<_MemberAction>(
                    value: _MemberAction.remove,
                    child: Text(l10n.teamMemberRemoveAction),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handle(BuildContext context, _MemberAction action) async {
    final l10n = context.l10n;
    final repository = getIt<TeamRepository>();

    if (action == _MemberAction.remove) {
      final confirmed = await showAppConfirm(
        context: context,
        title: l10n.teamMemberRemoveConfirmTitle(member.displayName),
        message: l10n.teamMemberRemoveConfirmMessage,
        confirmLabel: l10n.teamMemberRemoveAction,
        cancelLabel: l10n.actionCancel,
        isDestructive: true,
      );
      if (!confirmed || !context.mounted) {
        return;
      }
    }

    try {
      switch (action) {
        case _MemberAction.promote:
          await repository.setMemberRole(
            teamId: teamId,
            userId: member.userId,
            role: TeamRole.manager,
          );
        case _MemberAction.demote:
          await repository.setMemberRole(
            teamId: teamId,
            userId: member.userId,
            role: TeamRole.player,
          );
        case _MemberAction.remove:
          await repository.removeMember(teamId: teamId, userId: member.userId);
      }
      if (!context.mounted) {
        return;
      }
      final message = action == _MemberAction.remove
          ? l10n.teamMemberRemovedMessage
          : l10n.teamMemberRoleUpdatedMessage;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      unawaited(context.read<TeamStatusCubit>().load());
    } on AppFailure catch (failure) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.localizedMessage(l10n))));
    }
  }
}

enum _MemberAction { promote, demote, remove }

class _InviteMemberButton extends StatelessWidget {
  const _InviteMemberButton({required this.teamId});

  final String teamId;

  @override
  Widget build(BuildContext context) => AppButton.secondary(
    label: context.l10n.teamDetailInviteAction,
    icon: Icons.person_add_alt_outlined,
    expanded: true,
    onPressed: () => _showInviteSheet(context, teamId),
  );
}

Future<void> _showInviteSheet(BuildContext context, String teamId) =>
    showAppBottomSheet<void>(
      context: context,
      builder: (sheetContext) => _InviteMemberSheet(teamId: teamId),
    );

class _InviteMemberSheet extends StatefulWidget {
  const _InviteMemberSheet({required this.teamId});

  final String teamId;

  @override
  State<_InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends State<_InviteMemberSheet> {
  final TextEditingController _controller = TextEditingController();
  final RequestsRepository _repository = getIt<RequestsRepository>();
  bool _isSending = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppBottomSheet(
      title: l10n.teamInviteSheetTitle,
      actions: <Widget>[
        AppButton(
          label: l10n.teamInviteSendAction,
          expanded: true,
          isLoading: _isSending,
          onPressed: _isSending ? null : _send,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.teamInviteSlugFieldHint,
            style: context.textStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: _controller,
            label: l10n.teamInviteSlugFieldLabel,
            errorText: _errorMessage,
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final slug = _controller.text.trim();
    if (slug.isEmpty) {
      return;
    }
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });
    try {
      await _repository.inviteMember(teamId: widget.teamId, slug: slug);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.teamInviteSentMessage)),
      );
    } on AppFailure catch (failure) {
      if (!mounted) {
        return;
      }
      final message = failure is TeamFailure &&
              failure.reason == TeamFailureReason.notFound
          ? context.l10n.teamInviteNotFoundMessage
          : failure.localizedMessage(context.l10n);
      setState(() {
        _isSending = false;
        _errorMessage = message;
      });
    }
  }
}

/// Pedidos pendentes deste time -- filtrados da mesma caixa de entrada
/// global da tab Solicitacoes, so pra nao obrigar o OWNER/gerente a sair da
/// tela do time pra aprovar/recusar.
class _PendingRequestsSection extends StatelessWidget {
  const _PendingRequestsSection({required this.teamId});

  final String teamId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<RequestsCubit, RequestsState>(
      builder: (context, state) {
        final requests = state.inbox.joinRequestsToReview
            .where((r) => r.teamId == teamId)
            .toList(growable: false);
        if (requests.isEmpty) {
          return const SizedBox.shrink();
        }
        final cubit = context.read<RequestsCubit>();

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.teamPendingRequestsSectionTitle.toUpperCase(),
                style: context.textStyles.labelSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              for (final request in requests) ...<Widget>[
                Row(
                  children: <Widget>[
                    AppAvatar(
                      label: request.requesterDisplayName,
                      imageUrl: request.requesterAvatarUrl,
                      size: AppSizing.avatarMd,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            request.requesterDisplayName,
                            style: context.textStyles.bodyMedium,
                          ),
                          Text(
                            request.teamName,
                            style: context.textStyles.bodySmall?.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: l10n.requestsRejectAction,
                      onPressed: () => cubit.rejectJoinRequest(request.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check),
                      tooltip: l10n.requestsApproveAction,
                      onPressed: () => cubit.approveJoinRequest(request.id),
                    ),
                  ],
                ),
                if (request != requests.last)
                  const Divider(height: AppSpacing.lg),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Convites que o proprio time enviou e ainda estao PENDING -- unico lugar
/// que oferece cancelar (revoke_team_invitation ja existia sem UI nenhuma
/// que o chamasse).
class _SentInvitationsSection extends StatefulWidget {
  const _SentInvitationsSection({required this.teamId});

  final String teamId;

  @override
  State<_SentInvitationsSection> createState() =>
      _SentInvitationsSectionState();
}

class _SentInvitationsSectionState extends State<_SentInvitationsSection> {
  late Future<List<SentTeamInvitation>> _future;
  final Set<String> _revokingIds = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = getIt<RequestsRepository>().fetchSentInvitations(widget.teamId);
  }

  Future<void> _revoke(String invitationId) async {
    setState(() => _revokingIds.add(invitationId));
    try {
      await getIt<RequestsRepository>().revokeInvitation(invitationId);
      if (!mounted) {
        return;
      }
      setState(() {
        _revokingIds.remove(invitationId);
        _load();
      });
    } on AppFailure catch (failure) {
      if (!mounted) {
        return;
      }
      setState(() => _revokingIds.remove(invitationId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.localizedMessage(context.l10n))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FutureBuilder<List<SentTeamInvitation>>(
      future: _future,
      builder: (context, snapshot) {
        final invitations = snapshot.data ?? const <SentTeamInvitation>[];
        if (invitations.isEmpty) {
          return const SizedBox.shrink();
        }

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.teamSentInvitationsSectionTitle.toUpperCase(),
                style: context.textStyles.labelSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              for (final invitation in invitations) ...<Widget>[
                Row(
                  children: <Widget>[
                    AppAvatar(
                      label: invitation.inviteeDisplayName,
                      imageUrl: invitation.inviteeAvatarUrl,
                      size: AppSizing.avatarMd,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        invitation.inviteeDisplayName,
                        style: context.textStyles.bodyMedium,
                      ),
                    ),
                    if (_revokingIds.contains(invitation.id))
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: AppLoading.inline(),
                      )
                    else
                      AppButton.ghost(
                        label: l10n.teamInviteRevokeAction,
                        onPressed: () => _revoke(invitation.id),
                      ),
                  ],
                ),
                if (invitation != invitations.last)
                  const Divider(height: AppSpacing.lg),
              ],
            ],
          ),
        );
      },
    );
  }
}
