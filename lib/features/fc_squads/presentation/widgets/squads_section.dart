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

/// "Escalação Principal" no detalhe da Conta.
///
/// Uma Conta tem no máximo um Elenco ativo (índice único parcial em
/// `is_active`, `list_fc_squads` já filtra por ele) — não há mais "outras
/// escalações" a listar, então a tela vai direto de "sem elenco" para
/// "montar" ou de "tem elenco" para "editar", sem gerenciador de lista.
class SquadsSection extends StatelessWidget {
  const SquadsSection({required this.fcAccountId, super.key});

  final String fcAccountId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<FcSquadsCubit, FcSquadsState>(
      builder: (context, state) {
        // Só mostra squads do elenco aberto: se o cubit ainda está com outra
        // conta carregada, espera em vez de exibir dado alheio.
        if (state.accountId != fcAccountId) {
          return const SizedBox.shrink();
        }

        final primary = state.defaultSquad ?? state.squads.firstOrNull;

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                l10n.squadPrimaryLineupTitle.toUpperCase(),
                style: context.textStyles.labelSmall,
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
              else if (primary == null) ...<Widget>[
                Text(
                  l10n.squadPrimaryLineupEmpty,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton.secondary(
                  label: l10n.squadPrimaryLineupCreateAction,
                  icon: Icons.add,
                  onPressed: state.isSaving
                      ? null
                      : () => _create(context, state),
                ),
              ] else ...<Widget>[
                _PrimarySummary(squad: primary),
                const SizedBox(height: AppSpacing.lg),
                AppButton.secondary(
                  label: l10n.squadPrimaryLineupEditAction,
                  icon: Icons.tune,
                  onPressed: () => context.pushNamed(
                    AppRoutes.squadBuilder.name,
                    pathParameters: <String, String>{
                      AppRoutes.squadIdParam: primary.id,
                    },
                  ),
                ),
              ],
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

class _PrimarySummary extends StatelessWidget {
  const _PrimarySummary({required this.squad});

  final FcSquadSummary squad;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final isComplete = squad.startingCount >= 11;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Flexible(
              child: Text(
                squad.name,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.titleMedium,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppBadge(label: squad.formationCode),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            AppBadge(
              label: squad.overall == null
                  ? l10n.squadOverallUnknown
                  : l10n.squadOverallValue(squad.overall!),
            ),
            AppBadge(
              label: l10n.squadChemistryValue(squad.chemistry),
              tone: squad.chemistry >= 24
                  ? AppBadgeTone.success
                  : squad.chemistry >= 12
                  ? AppBadgeTone.warning
                  : AppBadgeTone.neutral,
            ),
            // Escalação incompleta é informação, não erro: buscar partida
            // continua liberado (item 52).
            if (!isComplete)
              AppBadge(
                label: l10n.squadCompletionLabel(squad.startingCount, 11),
                tone: AppBadgeTone.warning,
              ),
          ],
        ),
        if (isComplete) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.squadCompletionLabel(squad.startingCount, 11),
            style: context.textStyles.bodySmall?.copyWith(
              color: colors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }
}
