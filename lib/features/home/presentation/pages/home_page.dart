import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/game/presentation/widgets/pending_match_card.dart';
import 'package:fifa_queue/features/game/presentation/widgets/weekend_league_card.dart';
import 'package:fifa_queue/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_membership.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_state.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Inicio: resumo leve + atalhos. O hub de partida propriamente dito (conta,
/// modo, squad, fila) mora no Controle -- Inicio nunca duplica formulario.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
                  eyebrow: l10n.startEyebrow,
                  title: l10n.startTitle,
                  subtitle: l10n.startSubtitle,
                ),
                Expanded(
                  child: _HomeBody(state: state, selected: selected),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.state, required this.selected});

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
      return const TeamEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      children: const <Widget>[
        WeekendLeagueCard(),
        PendingMatchCard(),
        _ShortcutsGrid(),
      ],
    );
  }
}

class _ShortcutsGrid extends StatelessWidget {
  const _ShortcutsGrid();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.startShortcutsTitle.toUpperCase(),
          style: context.textStyles.labelSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            Expanded(
              child: _ShortcutCard(
                icon: Icons.groups_outlined,
                label: l10n.navTeam,
                onTap: () => context.go(AppRoutes.team.path),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _ShortcutCard(
                icon: Icons.history,
                label: l10n.navHistory,
                onTap: () => context.go(AppRoutes.history.path),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _ShortcutCard(
                icon: Icons.sports_esports_outlined,
                label: l10n.navControl,
                onTap: () => context.go(AppRoutes.control.path),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: context.colors.success),
        const SizedBox(height: AppSpacing.sm),
        Text(label, style: context.textStyles.bodyMedium),
      ],
    ),
  );
}
