import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_state.dart';
import 'package:fifa_queue/features/game/presentation/cubit/pending_match_cubit.dart';
import 'package:fifa_queue/features/game/presentation/widgets/pending_match_card.dart';
import 'package:fifa_queue/features/game/presentation/widgets/rivals_card.dart';
import 'package:fifa_queue/features/game/presentation/widgets/weekend_league_card.dart';
import 'package:fifa_queue/features/home/presentation/widgets/home_fc_account_card.dart';
import 'package:fifa_queue/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_membership.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_state.dart';
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

    return RefreshIndicator(
      onRefresh: () => Future.wait(<Future<void>>[
        context.read<TeamsCubit>().refresh(),
        context.read<FcAccountsCubit>().refresh(),
        context.read<PendingMatchCubit>().refreshSilently(),
      ]),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: <Widget>[
          const HomeFcAccountCard(),
          const WeekendLeagueCard(),
          const RivalsCard(),
          const PendingMatchCard(),
          if (selected == null) const _NoTeamCard(),
          const _ShortcutsGrid(),
        ],
      ),
    );
  }
}

/// Sem time a Home continua util (Rivals e Weekend League sao da Conta FC),
/// entao o convite para entrar num time e um card no fluxo -- nunca um
/// bloqueio de tela inteira, que era o que escondia a identidade FC.
///
/// So aparece depois que existe Conta FC: sem nenhuma, o texto prometeria
/// Rivals e Weekend League que ainda nao da pra usar, e competiria com o
/// convite de criar a primeira conta, que e a acao certa naquele momento.
class _NoTeamCard extends StatelessWidget {
  const _NoTeamCard();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<FcAccountsCubit, FcAccountsState>(
        buildWhen: (previous, current) =>
            previous.hasAccounts != current.hasAccounts,
        builder: (context, state) => state.hasAccounts
            ? const _NoTeamCardBody()
            : const SizedBox.shrink(),
      );
}

class _NoTeamCardBody extends StatelessWidget {
  const _NoTeamCardBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: AppCard(
        onTap: () => context.go(AppRoutes.team.path),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.groups_outlined,
              size: AppSizing.iconLg,
              color: context.colors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.homeNoTeamTitle,
                    style: context.textStyles.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    l10n.homeNoTeamMessage,
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
    );
  }
}

/// Atalhos com dois pesos, nao seis cards iguais: a acao principal ocupa a
/// largura toda, o dia a dia vira uma fileira compacta e o catalogo (consulta,
/// nao operacao) fica agrupado embaixo. Nenhum icone verde -- hierarquia aqui
/// vem de tamanho e superficie.
class _ShortcutsGrid extends StatelessWidget {
  const _ShortcutsGrid();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SectionLabel(text: l10n.startShortcutsTitle),
        const SizedBox(height: AppSpacing.md),
        _PrimaryShortcut(
          icon: Icons.sports_esports_outlined,
          label: l10n.navControl,
          description: l10n.startShortcutPlayHint,
          onTap: () => context.go(AppRoutes.control.path),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            Expanded(
              child: _CompactShortcut(
                icon: Icons.person_outline,
                label: l10n.profileFcAccountsRow,
                onTap: () => context.push(AppRoutes.fcAccounts.path),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _CompactShortcut(
                icon: Icons.groups_outlined,
                label: l10n.navTeam,
                onTap: () => context.go(AppRoutes.team.path),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _CompactShortcut(
                icon: Icons.history,
                label: l10n.navHistory,
                onTap: () => context.go(AppRoutes.history.path),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionLabel(text: l10n.startCatalogTitle),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            Expanded(
              child: _CatalogShortcut(
                icon: Icons.style_outlined,
                label: l10n.catalogCardsTitle,
                description: l10n.startCatalogCardsHint,
                onTap: () => context.push(AppRoutes.cardsCatalog.path),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _CatalogShortcut(
                icon: Icons.shield_outlined,
                label: l10n.catalogClubsTitle,
                description: l10n.startCatalogClubsHint,
                onTap: () => context.push(AppRoutes.clubsCatalog.path),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: context.textStyles.labelSmall?.copyWith(
      color: context.colors.textTertiary,
      letterSpacing: 1.4,
    ),
  );
}

class _PrimaryShortcut extends StatelessWidget {
  const _PrimaryShortcut({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppCard(
      variant: AppCardVariant.elevated,
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            width: AppSizing.iconXl,
            height: AppSizing.iconXl,
            decoration: BoxDecoration(
              color: colors.surfaceHighest,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: AppSizing.iconMd,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: context.textStyles.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  description,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colors.textTertiary),
        ],
      ),
    );
  }
}

class _CompactShortcut extends StatelessWidget {
  const _CompactShortcut({
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
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.md,
    ),
    child: Column(
      children: <Widget>[
        Icon(icon, color: context.colors.textSecondary),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: context.textStyles.bodySmall,
        ),
      ],
    ),
  );
}

class _CatalogShortcut extends StatelessWidget {
  const _CatalogShortcut({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppCard(
      variant: AppCardVariant.outlined,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: colors.textSecondary),
          const SizedBox(height: AppSpacing.md),
          Text(label, style: context.textStyles.titleSmall),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
