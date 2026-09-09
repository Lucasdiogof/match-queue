import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_state.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/fc_account_onboarding_card.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/fc_account_selector_row.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_manager.dart';
import 'package:fifa_queue/features/fc_squads/domain/repositories/player_card_catalog_repository.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/player_picker_sheet.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/squad_selector_row.dart';
import 'package:fifa_queue/features/game/presentation/cubit/pending_match_cubit.dart';
import 'package:fifa_queue/features/matchmaking/presentation/widgets/game_mode_selector.dart';
import 'package:fifa_queue/features/matchmaking/presentation/widgets/matchmaking_section.dart';
import 'package:fifa_queue/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_membership.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// O Controle e o hub operacional do FIFA Queue -- contexto ativo (conta,
/// modo, squad, fila) quando existe, e cartoes de descoberta do catalogo FC27
/// (cartas/clubes) quando nao. Nunca uma tela vazia so com icone+frase.
class ControlPage extends StatelessWidget {
  const ControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<TeamsCubit, TeamsState>(
      builder: (context, state) {
        final selected = state.selectedTeam;
        return AppScaffold(
          appBar: const AppAppBar(actions: <Widget>[NotificationBellButton()]),
          body: AppBackground(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                FeatureHeader(
                  eyebrow: l10n.controlEyebrow,
                  title: l10n.controlTitle,
                  subtitle: l10n.controlSubtitle,
                ),
                Expanded(
                  child: _ControlBody(state: state, selected: selected),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ControlBody extends StatelessWidget {
  const _ControlBody({required this.state, required this.selected});

  final TeamsState state;
  final UserTeam? selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (state.isLoading && !state.hasTeams) {
      return const AppLoading();
    }

    if (state.status == TeamsStatus.failure && !state.hasTeams) {
      return AppErrorState(
        title: l10n.teamLoadErrorTitle,
        message: state.failure?.localizedMessage(l10n) ?? l10n.errorUnexpected,
        retryLabel: l10n.actionRetry,
        onRetry: () => context.read<TeamsCubit>().refresh(),
      );
    }

    if (selected == null) {
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: <Widget>[
          AppEmptyState(
            icon: Icons.sports_soccer_outlined,
            title: l10n.controlEmptyTitle,
            message: l10n.controlEmptyMessage,
          ),
          const SizedBox(height: AppSpacing.xl),
          const _DiscoverySection(),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      children: <Widget>[
        BlocBuilder<FcAccountsCubit, FcAccountsState>(
          buildWhen: (previous, current) =>
              previous.status != current.status ||
              previous.accounts != current.accounts ||
              previous.selectedAccountId != current.selectedAccountId,
          builder: (context, fcState) {
            if (fcState.isLoading && fcState.accounts.isEmpty) {
              return const SizedBox.shrink();
            }
            if (!fcState.hasAccounts) {
              return const FcAccountOnboardingCard();
            }
            final account = fcState.selectedAccount;
            final hasActiveQueueContext = account != null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const FcAccountSelectorRow(),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.gameModeSectionTitle,
                        style: context.textStyles.labelSmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const GameModeSelector(),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const AppCard(child: SquadSelectorRow()),
                const SizedBox(height: AppSpacing.xl),
                if (account != null)
                  MatchmakingSection(
                    fcAccountId: account.id,
                    onMatchFound: () =>
                        context.read<PendingMatchCubit>().refreshSilently(),
                  ),
                if (!hasActiveQueueContext) ...<Widget>[
                  const SizedBox(height: AppSpacing.xl),
                  const _DiscoverySection(),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Descoberta do catalogo FC27, visivel mesmo sem fila ativa. Nunca duplica
/// o Squad Builder -- "Explorar cartas" reaproveita o mesmo picker sheet
/// (positionCode: null, sem slot) so pra navegar, e "Clubes" mostra os
/// agregados reais de get_fc_club_catalog_summary.
class _DiscoverySection extends StatelessWidget {
  const _DiscoverySection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppCard(
          onTap: () => showPlayerPickerSheet(context: context),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.style_outlined,
                size: AppSizing.iconLg,
                color: context.colors.success,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.controlDiscoverCardsTitle,
                      style: context.textStyles.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      l10n.controlDiscoverCardsSubtitle,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.colors.textTertiary),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.shield_outlined,
                    size: AppSizing.iconLg,
                    color: context.colors.success,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          l10n.controlDiscoverClubsTitle,
                          style: context.textStyles.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          l10n.controlDiscoverClubsSubtitle,
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
              SizedBox(
                height: 88,
                child: FutureBuilder<List<FcClubSummary>>(
                  future: getIt<PlayerCardCatalogRepository>()
                      .getClubCatalogSummary(),
                  builder: (context, snapshot) {
                    final clubs = snapshot.data;
                    if (clubs == null) {
                      return const AppLoading.inline();
                    }
                    if (clubs.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: clubs.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, index) =>
                          _ClubChipCard(summary: clubs[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClubChipCard extends StatelessWidget {
  const _ClubChipCard({required this.summary});

  final FcClubSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: 128,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceHighest,
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            summary.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.bodyMedium,
          ),
          Text(
            <String>[
              if (summary.averageRating != null) '${summary.averageRating}',
              '${summary.cardCount}',
            ].join(' · '),
            style: context.textStyles.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
