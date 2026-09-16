import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/profiles/presentation/cubit/profiles_cubit.dart';
import 'package:fifa_queue/features/profiles/presentation/cubit/profiles_state.dart';
import 'package:fifa_queue/features/profiles/presentation/widgets/profile_onboarding_card.dart';
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
      appBar: AppAppBar(
        title: l10n.navCentral,
        accentTitle: true,
        actions: const <Widget>[NotificationBellButton()],
      ),
      body: const AppBackground(child: _CentralBody()),
    );
  }
}

class _CentralBody extends StatelessWidget {
  const _CentralBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Unico dado desta tela que pode ficar "preso" (ex.: primeiro fetch do
    // boot que nao completou) e o de ProfilesCubit, pro card de
    // onboarding -- puxar pra atualizar da pro usuario um jeito de tentar
    // de novo sem precisar trocar de aba.
    return RefreshIndicator(
      onRefresh: () => context.read<ProfilesCubit>().refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: <Widget>[
          BlocBuilder<ProfilesCubit, ProfilesState>(
            buildWhen: (previous, current) =>
                previous.status != current.status ||
                previous.hasProfiles != current.hasProfiles,
            // Enquanto ainda carrega (ex.: primeiro fetch do boot, que corre
            // em paralelo com a primeira tela), "profiles vazio" nao significa
            // "usuario sem conta" -- so significa "ainda nao sabemos". Sem
            // este guard, quem ja tem conta via o card de criar a primeira
            // ate a resposta chegar, que em uma rede lenta da pra notar (mesmo
            // guard que ControlPage ja usa nos dois ramos dela).
            builder: (context, state) {
              if (state.isLoading && state.profiles.isEmpty) {
                return const SizedBox.shrink();
              }
              if (state.hasProfiles) {
                return const SizedBox.shrink();
              }
              return const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.xl),
                child: ProfileOnboardingCard(),
              );
            },
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
      ),
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
