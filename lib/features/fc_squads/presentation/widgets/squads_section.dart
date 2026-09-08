import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_squad.dart';
import 'package:fifa_queue/features/fc_squads/presentation/cubit/fc_squads_cubit.dart';
import 'package:fifa_queue/features/fc_squads/presentation/cubit/fc_squads_state.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/squad_name_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Seção "Squads" dentro do detalhe do Elenco.
class SquadsSection extends StatelessWidget {
  const SquadsSection({required this.fcAccountId, super.key});

  final String fcAccountId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<FcSquadsCubit, FcSquadsState>(
      builder: (context, state) {
        // Só mostra squads do elenco aberto: se o cubit ainda está com outra
        // conta carregada, espera em vez de exibir dado alheio (item 127).
        if (state.accountId != fcAccountId) {
          return const SizedBox.shrink();
        }

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    l10n.squadsSectionTitle.toUpperCase(),
                    style: context.textStyles.labelSmall,
                  ),
                  if (state.hasSquads)
                    Text(
                      '${state.squads.length}',
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (state.isLoading)
                const SizedBox(height: 64, child: AppLoading.inline())
              else if (state.status == FcSquadsStatus.failure)
                AppBanner(
                  tone: AppBannerTone.danger,
                  message:
                      state.failure?.localizedMessage(l10n) ??
                      l10n.errorUnexpected,
                )
              else if (!state.hasSquads)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    l10n.squadsEmptyMessage,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                )
              else
                for (final squad in state.squads)
                  _SquadRow(squad: squad, accountId: fcAccountId),
              const SizedBox(height: AppSpacing.sm),
              AppButton.secondary(
                label: l10n.squadCreateAction,
                icon: Icons.add,
                onPressed: state.isSaving
                    ? null
                    : () => _create(context, state),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _create(BuildContext context, FcSquadsState state) async {
    final l10n = context.l10n;
    final cubit = context.read<FcSquadsCubit>();
    final result = await showSquadNameSheet(
      context: context,
      title: l10n.squadCreateTitle,
      subtitle: l10n.squadCreateSubtitle,
      formations: state.formations,
    );
    if (result == null || result.formationCode == null) {
      return;
    }
    await cubit.createSquad(
      name: result.name,
      formationCode: result.formationCode!,
    );
  }
}

class _SquadRow extends StatelessWidget {
  const _SquadRow({required this.squad, required this.accountId});

  final FcSquadSummary squad;
  final String accountId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return InkWell(
      onTap: () => context.pushNamed(
        AppRoutes.squadBuilder.name,
        pathParameters: <String, String>{AppRoutes.squadIdParam: squad.id},
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          squad.name,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.bodyLarge,
                        ),
                      ),
                      if (squad.isDefault) ...<Widget>[
                        const SizedBox(width: AppSpacing.sm),
                        AppBadge(label: l10n.squadDefaultBadge),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${squad.formationCode} · '
                    '${l10n.squadCompletionLabel(squad.startingCount, 11)}',
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
      ),
    );
  }
}
