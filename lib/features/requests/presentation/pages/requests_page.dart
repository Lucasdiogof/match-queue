import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/requests/domain/entities/requests_inbox.dart';
import 'package:fifa_queue/features/requests/presentation/cubit/requests_cubit.dart';
import 'package:fifa_queue/features/requests/presentation/cubit/requests_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<RequestsCubit>().load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: AppAppBar(
        title: l10n.requestsPageTitle,
        accentTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          // Contagem no rotulo depende do inbox -- so essa parte precisa
          // reconstruir quando ele muda, a TabBar em si e estatica.
          child: BlocBuilder<RequestsCubit, RequestsState>(
            buildWhen: (previous, current) => previous.inbox != current.inbox,
            builder: (context, state) => TabBar(
              controller: _tabController,
              tabs: <Widget>[
                Tab(
                  text: state.inbox.joinRequestsToReview.isEmpty
                      ? l10n.requestsSegmentRequests
                      : '${l10n.requestsSegmentRequests} '
                            '(${state.inbox.joinRequestsToReview.length})',
                ),
                Tab(
                  text: state.inbox.invitationsReceived.isEmpty
                      ? l10n.requestsSegmentInvites
                      : '${l10n.requestsSegmentInvites} '
                            '(${state.inbox.invitationsReceived.length})',
                ),
              ],
            ),
          ),
        ),
      ),
      body: AppBackground(
        child: BlocBuilder<RequestsCubit, RequestsState>(
          builder: (context, state) {
            if (state.isLoading && state.inbox.pendingCount == 0) {
              return const AppLoading();
            }
            if (state.status == RequestsStatus.failure &&
                state.inbox.pendingCount == 0) {
              return AppErrorState(
                title: l10n.requestsLoadErrorTitle,
                message:
                    state.failure?.localizedMessage(l10n) ??
                    l10n.errorUnexpected,
                retryLabel: l10n.actionRetry,
                onRetry: () => context.read<RequestsCubit>().refresh(),
              );
            }
            return TabBarView(
              controller: _tabController,
              children: <Widget>[
                RefreshIndicator(
                  onRefresh: () => context.read<RequestsCubit>().refresh(),
                  child: _JoinRequestsList(
                    requests: state.inbox.joinRequestsToReview,
                    pendingActionIds: state.pendingActionIds,
                  ),
                ),
                RefreshIndicator(
                  onRefresh: () => context.read<RequestsCubit>().refresh(),
                  child: _InvitationsList(
                    invitations: state.inbox.invitationsReceived,
                    pendingActionIds: state.pendingActionIds,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _JoinRequestsList extends StatelessWidget {
  const _JoinRequestsList({
    required this.requests,
    required this.pendingActionIds,
  });

  final List<TeamJoinRequestSummary> requests;
  final Set<String> pendingActionIds;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (requests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          const SizedBox(height: AppSpacing.huge),
          AppEmptyState(
            icon: Icons.inbox_outlined,
            title: l10n.requestsEmptyRequestsTitle,
            message: l10n.requestsEmptyRequestsMessage,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      itemCount: requests.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final request = requests[index];
        final isBusy = pendingActionIds.contains(request.id);
        final cubit = context.read<RequestsCubit>();

        return AppCard(
          onTap: () => context.push(
            AppRoutes.playerProfileLocation(
              request.teamId,
              request.requesterUserId,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
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
                          style: context.textStyles.bodyLarge,
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
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppButton.secondary(
                      label: l10n.requestsRejectAction,
                      isLoading: isBusy,
                      onPressed: isBusy
                          ? null
                          : () => cubit.rejectJoinRequest(request.id),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: l10n.requestsApproveAction,
                      isLoading: isBusy,
                      onPressed: isBusy
                          ? null
                          : () => cubit.approveJoinRequest(request.id),
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
}

class _InvitationsList extends StatelessWidget {
  const _InvitationsList({
    required this.invitations,
    required this.pendingActionIds,
  });

  final List<TeamInvitationSummary> invitations;
  final Set<String> pendingActionIds;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (invitations.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          const SizedBox(height: AppSpacing.huge),
          AppEmptyState(
            icon: Icons.mail_outline,
            title: l10n.requestsEmptyInvitesTitle,
            message: l10n.requestsEmptyInvitesMessage,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      itemCount: invitations.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final invitation = invitations[index];
        final isBusy = pendingActionIds.contains(invitation.id);
        final cubit = context.read<RequestsCubit>();

        return AppCard(
          onTap: () =>
              context.push(AppRoutes.publicTeamLocation(invitation.teamId)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  AppAvatar(
                    label: invitation.teamName,
                    imageUrl: invitation.teamLogoUrl,
                    size: AppSizing.avatarMd,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          invitation.teamName,
                          style: context.textStyles.bodyLarge,
                        ),
                        Text(
                          l10n.requestsMemberCountLabel(invitation.memberCount),
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppButton.secondary(
                      label: l10n.requestsDeclineAction,
                      isLoading: isBusy,
                      onPressed: isBusy
                          ? null
                          : () => cubit.declineInvitation(invitation.id),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: l10n.requestsAcceptAction,
                      isLoading: isBusy,
                      onPressed: isBusy
                          ? null
                          : () => cubit.acceptInvitation(invitation.id),
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
}
