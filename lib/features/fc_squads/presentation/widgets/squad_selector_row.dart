import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/fc_squads/presentation/cubit/fc_squads_cubit.dart';
import 'package:fifa_queue/features/fc_squads/presentation/cubit/fc_squads_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Linha compacta "Squad: Principal · 4-2-3-1" no Jogar.
///
/// Trocar aqui vale só para a próxima busca; o default do elenco continua
/// como está (item 70). Sem nenhum squad, oferece criar mas não bloqueia o
/// matchmaking.
class SquadSelectorRow extends StatelessWidget {
  const SquadSelectorRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return BlocBuilder<FcSquadsCubit, FcSquadsState>(
      builder: (context, state) {
        if (state.accountId == null) {
          return const SizedBox.shrink();
        }

        final selected = state.selectedSquad;

        final subtitle = selected == null
            ? l10n.squadNoneSelectedHint
            : selected.startingCount < 11
            ? l10n.squadCompletionLabel(selected.startingCount, 11)
            : '${selected.formationCode} · '
                  '${selected.overall == null ? l10n.squadOverallUnknown : l10n.squadOverallValue(selected.overall!)}'
                  ' · ${l10n.squadChemistryValue(selected.chemistry)}';

        return AppCard(
          onTap: () => _onTap(context, state),
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
                  Icons.grid_view_rounded,
                  size: AppSizing.iconSm,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      l10n.squadLabel.toUpperCase(),
                      style: context.textStyles.labelSmall?.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      selected?.name ?? l10n.squadNoneSelected,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.unfold_more,
                size: AppSizing.iconSm,
                color: colors.textTertiary,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onTap(BuildContext context, FcSquadsState state) async {
    final l10n = context.l10n;
    final cubit = context.read<FcSquadsCubit>();

    await showAppBottomSheet<void>(
      context: context,
      builder: (sheetContext) => AppBottomSheet(
        title: l10n.squadLabel,
        isChildScrollable: true,
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            if (!state.hasSquads)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Text(
                  l10n.squadsEmptyMessage,
                  style: sheetContext.textStyles.bodySmall,
                ),
              )
            else
              for (final squad in state.squads)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    borderColor: squad.id == state.selectedSquadId
                        ? sheetContext.colors.textPrimary
                        : null,
                    onTap: () {
                      cubit.selectForNextSearch(squad.id);
                      Navigator.of(sheetContext).pop();
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            l10n.squadSummaryLabel(
                              squad.name,
                              squad.formationCode,
                            ),
                            overflow: TextOverflow.ellipsis,
                            style: sheetContext.textStyles.bodyLarge,
                          ),
                        ),
                        if (squad.isDefault)
                          AppBadge(label: l10n.squadDefaultBadge),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: AppSpacing.sm),
            AppButton.secondary(
              label: l10n.squadsSectionTitle,
              icon: Icons.open_in_new,
              onPressed: () {
                Navigator.of(sheetContext).pop();
                final accountId = state.accountId;
                if (accountId != null) {
                  context.push(AppRoutes.fcAccountDetailLocation(accountId));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
