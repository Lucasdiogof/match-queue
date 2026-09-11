import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_state.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/fc_account_onboarding_card.dart';
import 'package:fifa_queue/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Central: hub de consulta do FC 27 (catálogo, mecânicas, controles).
///
/// Substitui a antiga Home -- nunca mostra estado de partida/fila (isso é
/// o Jogar) nem atalhos operacionais. O único conteúdo condicional é o
/// onboarding de Conta FC, porque sem Home não sobrou nenhuma tela que
/// convidasse quem acabou de entrar a criar a primeira conta.
class CentralPage extends StatelessWidget {
  const CentralPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: const AppAppBar(actions: <Widget>[NotificationBellButton()]),
      body: AppBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            FeatureHeader(title: l10n.navCentral),
            const Expanded(child: _CentralBody()),
          ],
        ),
      ),
    );
  }
}

class _CentralBody extends StatelessWidget {
  const _CentralBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      children: <Widget>[
        BlocBuilder<FcAccountsCubit, FcAccountsState>(
          buildWhen: (previous, current) =>
              previous.hasAccounts != current.hasAccounts,
          builder: (context, state) => state.hasAccounts
              ? const SizedBox.shrink()
              : const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.xl),
                  child: FcAccountOnboardingCard(),
                ),
        ),
        _SectionLabel(text: l10n.centralSectionCatalog),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            Expanded(
              child: _BigEntryCard(
                icon: Icons.style_outlined,
                label: l10n.catalogCardsTitle,
                description: l10n.startCatalogCardsHint,
                onTap: () => context.push(AppRoutes.cardsCatalog.path),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _BigEntryCard(
                icon: Icons.shield_outlined,
                label: l10n.catalogClubsTitle,
                description: l10n.startCatalogClubsHint,
                onTap: () => context.push(AppRoutes.clubsCatalog.path),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            Expanded(
              child: _CompactEntryCard(
                icon: Icons.groups_2_outlined,
                label: l10n.catalogManagersEntryLabel,
                onTap: () => context.push(AppRoutes.managersCatalog.path),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _CompactEntryCard(
                icon: Icons.inventory_2_outlined,
                label: l10n.catalogConsumablesEntryLabel,
                onTap: () => context.push(AppRoutes.consumablesCatalog.path),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionLabel(text: l10n.centralSectionMechanics),
        const SizedBox(height: AppSpacing.md),
        _ListEntryRow(
          icon: Icons.auto_awesome_outlined,
          label: l10n.mechanicsPlaystylesLabel,
          description: l10n.mechanicsPlaystylesHint,
          onTap: () => context.push(AppRoutes.playstyles.path),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ListEntryRow(
          icon: Icons.science_outlined,
          label: l10n.mechanicsChemistryLabel,
          description: l10n.mechanicsChemistryHint,
          onTap: () => context.push(AppRoutes.chemistry.path),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ListEntryRow(
          icon: Icons.bolt_outlined,
          label: l10n.mechanicsChemistryStylesLabel,
          description: l10n.mechanicsChemistryStylesHint,
          onTap: () => context.push(AppRoutes.chemistryStyles.path),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ListEntryRow(
          icon: Icons.trending_up_outlined,
          label: l10n.mechanicsEvolutionsLabel,
          description: l10n.mechanicsEvolutionsHint,
          onTap: () => context.push(AppRoutes.evolutions.path),
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionLabel(text: l10n.centralSectionControls),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            Expanded(
              child: _CompactEntryCard(
                icon: Icons.sports_soccer_outlined,
                label: l10n.controlsDribblingLabel,
                onTap: () => context.push(AppRoutes.controlsDribbling.path),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _CompactEntryCard(
                icon: Icons.swap_horiz,
                label: l10n.controlsPassingLabel,
                onTap: () => context.push(AppRoutes.controlsPassing.path),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            Expanded(
              child: _CompactEntryCard(
                icon: Icons.adjust_outlined,
                label: l10n.controlsShootingLabel,
                onTap: () => context.push(AppRoutes.controlsShooting.path),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _CompactEntryCard(
                icon: Icons.shield_moon_outlined,
                label: l10n.controlsDefendingLabel,
                onTap: () => context.push(AppRoutes.controlsDefending.path),
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

class _BigEntryCard extends StatelessWidget {
  const _BigEntryCard({
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
          Icon(icon, color: colors.textSecondary, size: AppSizing.iconLg),
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

class _CompactEntryCard extends StatelessWidget {
  const _CompactEntryCard({
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

class _ListEntryRow extends StatelessWidget {
  const _ListEntryRow({
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
            child: Icon(icon, color: colors.textPrimary),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
