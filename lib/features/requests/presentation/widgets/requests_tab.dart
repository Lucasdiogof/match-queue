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

/// Conteudo de "Convites": convites que o usuario recebeu de times +
/// pedidos pra entrar nos times que ele administra. Vive como uma aba de
/// Times, sem Scaffold/AppBar proprio (quem fornece e TeamsListPage).
///
/// Uma lista so, com as duas listas empilhadas em secoes. Antes eram duas
/// sub-abas, mas a de dentro se chamava "Convites" igual a aba-mae -- e
/// duas abas pra, no uso normal, duas listas curtas (quase sempre uma
/// vazia) cobravam um toque a mais pra descobrir que nao havia nada do
/// outro lado. Secao vazia simplesmente nao aparece; quando as duas estao
/// vazias, um unico estado vazio explica as duas coisas.
class RequestsTab extends StatefulWidget {
  const RequestsTab({super.key});

  @override
  State<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<RequestsTab> {
  @override
  void initState() {
    super.initState();
    context.read<RequestsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<RequestsCubit, RequestsState>(
      builder: (context, state) {
        if (state.isLoading && state.inbox.pendingCount == 0) {
          return const AppLoading();
        }
        if (state.status == RequestsStatus.failure &&
            state.inbox.pendingCount == 0) {
          return AppErrorState(
            title: l10n.requestsLoadErrorTitle,
            message:
                state.failure?.localizedMessage(l10n) ?? l10n.errorUnexpected,
            retryLabel: l10n.actionRetry,
            onRetry: () => context.read<RequestsCubit>().refresh(),
          );
        }

        final invitations = state.inbox.invitationsReceived;
        final requests = state.inbox.joinRequestsToReview;

        return RefreshIndicator(
          onRefresh: () => context.read<RequestsCubit>().refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            children: <Widget>[
              if (invitations.isEmpty && requests.isEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.huge),
                AppEmptyState(
                  icon: Icons.inbox_outlined,
                  title: l10n.requestsEmptyAllTitle,
                  message: l10n.requestsEmptyAllMessage,
                ),
              ],
              // Convites primeiro: sao sobre o proprio usuario ("me
              // chamaram"), enquanto pedidos sao trabalho administrativo
              // sobre terceiros.
              if (invitations.isNotEmpty) ...<Widget>[
                _SectionTitle(label: l10n.requestsSegmentInvites),
                for (final invitation in invitations) ...<Widget>[
                  _InvitationCard(
                    invitation: invitation,
                    isBusy: state.pendingActionIds.contains(invitation.id),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
              if (requests.isNotEmpty) ...<Widget>[
                if (invitations.isNotEmpty)
                  const SizedBox(height: AppSpacing.lg),
                _SectionTitle(label: l10n.requestsSegmentRequests),
                for (final request in requests) ...<Widget>[
                  _JoinRequestCard(
                    request: request,
                    isBusy: state.pendingActionIds.contains(request.id),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(label.toUpperCase(), style: context.textStyles.labelSmall),
  );
}

class _JoinRequestCard extends StatelessWidget {
  const _JoinRequestCard({required this.request, required this.isBusy});

  final TeamJoinRequestSummary request;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<RequestsCubit>();

    return AppCard(
      // Sem onTap de propósito: quem pediu pra entrar ainda NÃO é membro do
      // time, e get_team_member_profile (por trás da rota de perfil do
      // jogador) exige isso -- tocar aqui sempre batia em "não tem permissão"
      // (FQ012 mal traduzido pra "convite" por reaproveitar o mesmo código
      // de erro). Sem um jeito seguro de mostrar mais do que já está no
      // card (nome, foto, time) sem a pessoa ainda ser membro, o card fica
      // só com os botões de Aprovar/Recusar interativos.
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
  }
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({required this.invitation, required this.isBusy});

  final TeamInvitationSummary invitation;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
  }
}
