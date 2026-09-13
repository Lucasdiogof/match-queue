import 'dart:async';

import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:fifa_queue/features/requests/domain/repositories/requests_repository.dart';
import 'package:fifa_queue/features/teams/domain/entities/team.dart';
import 'package:fifa_queue/features/teams/domain/repositories/team_repository.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Pagina publica de um time (aba Explorar). `found = false` cobre tanto
/// "nao existe" quanto "e privado" -- get_public_team nunca revela a
/// diferenca (mesma postura de PublicProfilePage).
class TeamPublicPage extends StatefulWidget {
  const TeamPublicPage({required this.teamId, super.key});

  final String teamId;

  @override
  State<TeamPublicPage> createState() => _TeamPublicPageState();
}

class _TeamPublicPageState extends State<TeamPublicPage> {
  late Future<PublicTeam> _future;

  @override
  void initState() {
    super.initState();
    _future = getIt<TeamRepository>().getPublicTeam(widget.teamId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: const AppAppBar(),
      body: AppBackground(
        dense: true,
        child: FutureBuilder<PublicTeam>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const AppLoading();
            }
            final team = snapshot.data!;
            if (!team.found) {
              return AppErrorState(
                title: l10n.teamPublicPageNotFoundTitle,
                message: l10n.teamPublicPageNotFoundMessage,
              );
            }
            return _TeamPublicBody(teamId: widget.teamId, team: team);
          },
        ),
      ),
    );
  }
}

class _TeamPublicBody extends StatelessWidget {
  const _TeamPublicBody({required this.teamId, required this.team});

  final String teamId;
  final PublicTeam team;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final record = team.record;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      children: <Widget>[
        Center(
          child: Column(
            children: <Widget>[
              CircleAvatar(
                radius: AppSizing.avatarLg,
                backgroundColor: colors.surfaceHighest,
                backgroundImage: team.logoUrl != null
                    ? NetworkImage(team.logoUrl!)
                    : null,
                child: team.logoUrl == null
                    ? Text(
                        team.name?.substring(0, 1).toUpperCase() ?? '?',
                        style: context.textStyles.titleLarge,
                      )
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(team.name ?? '', style: context.textStyles.headlineSmall),
              if (team.tag != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xxs),
                AppBadge(label: team.tag!),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (record != null) ...<Widget>[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.teamPublicPageRecordTitle.toUpperCase(),
                  style: context.textStyles.labelSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.teamPublicPageRecordLine(record.wins, record.losses),
                  style: context.textStyles.titleMedium,
                ),
                Text(
                  '${record.goalsFor}-${record.goalsAgainst}',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.teamPublicPageMembersTitle.toUpperCase(),
                style: context.textStyles.labelSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.teamMembersCount(team.memberCount),
                style: context.textStyles.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              if (team.members.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                // Um membro so aparece aqui se ele mesmo habilitou o
                // proprio perfil publico (get_public_team ja filtra) --
                // por isso todo mundo na lista tem slug e pode ser aberto.
                for (final member in team.members)
                  InkWell(
                    onTap: member.publicProfileSlug == null
                        ? null
                        : () => context.push(
                            AppRoutes.publicProfileLocation(
                              member.publicProfileSlug!,
                            ),
                          ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: <Widget>[
                          AppAvatar(
                            label: member.displayName,
                            imageUrl: member.avatarUrl,
                            size: AppSizing.avatarSm,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              member.displayName,
                              overflow: TextOverflow.ellipsis,
                              style: context.textStyles.bodyMedium,
                            ),
                          ),
                          if (member.publicProfileSlug != null)
                            Icon(
                              Icons.chevron_right,
                              size: AppSizing.iconMd,
                              color: colors.textTertiary,
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _JoinTeamSection(teamId: teamId),
      ],
    );
  }
}

/// CTA "Pedir para entrar" -- some por completo se o usuario ja e membro do
/// time (TeamsCubit.state.teams e a lista dos proprios times do usuario, ja
/// carregada no root do app).
class _JoinTeamSection extends StatefulWidget {
  const _JoinTeamSection({required this.teamId});

  final String teamId;

  @override
  State<_JoinTeamSection> createState() => _JoinTeamSectionState();
}

class _JoinTeamSectionState extends State<_JoinTeamSection> {
  final RequestsRepository _repository = getIt<RequestsRepository>();
  late Future<String?> _pendingRequestFuture;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pendingRequestFuture = _repository.myPendingRequestId(widget.teamId);
  }

  @override
  Widget build(BuildContext context) {
    final isMember = context.watch<TeamsCubit>().state.teams.any(
      (t) => t.id == widget.teamId,
    );
    if (isMember) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;

    return FutureBuilder<String?>(
      future: _pendingRequestFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final pendingRequestId = snapshot.data;
        if (pendingRequestId != null) {
          return AppButton.secondary(
            label: l10n.teamPublicRequestSentAction,
            expanded: true,
            icon: Icons.hourglass_top_outlined,
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : () => _cancel(pendingRequestId),
          );
        }
        return AppButton(
          label: l10n.teamPublicRequestToJoinAction,
          expanded: true,
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : _requestToJoin,
        );
      },
    );
  }

  Future<void> _cancel(String requestId) async {
    setState(() => _isSubmitting = true);
    try {
      await _repository.cancelJoinRequest(requestId);
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _pendingRequestFuture = Future<String?>.value(null);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.teamPublicRequestCancelledMessage)),
      );
    } on AppFailure catch (failure) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.localizedMessage(context.l10n))),
      );
    }
  }

  Future<void> _requestToJoin() async {
    final accounts = context.read<FcAccountsCubit>().state.accounts;
    if (accounts.isEmpty) {
      unawaited(context.push(AppRoutes.fcAccounts.path));
      return;
    }
    final fcAccountId = accounts.length == 1
        ? accounts.first.id
        : await _pickAccount(accounts);
    if (fcAccountId == null || !mounted) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _repository.requestToJoin(
        teamId: widget.teamId,
        fcAccountId: fcAccountId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _pendingRequestFuture = _repository.myPendingRequestId(widget.teamId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.teamPublicRequestSentMessage)),
      );
    } on AppFailure catch (failure) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.localizedMessage(context.l10n))),
      );
    }
  }

  Future<String?> _pickAccount(List<FcAccount> accounts) =>
      showAppBottomSheet<String>(
        context: context,
        builder: (sheetContext) => AppBottomSheet(
          title: sheetContext.l10n.teamPublicChooseAccountTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final account in accounts)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppButton.secondary(
                    label: account.name,
                    onPressed: () => Navigator.of(sheetContext).pop(account.id),
                  ),
                ),
            ],
          ),
        ),
      );
}
