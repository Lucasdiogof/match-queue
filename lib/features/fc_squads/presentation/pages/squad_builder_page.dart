import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_squad.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/formation.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/fc_squads/domain/repositories/fc_squad_repository.dart';
import 'package:fifa_queue/features/fc_squads/presentation/cubit/squad_builder_cubit.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/chemistry_sheets.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/formation_picker_sheet.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/manager_picker_sheet.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/player_card_detail_sheet.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/player_picker_sheet.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/squad_drag_payload.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/squad_field.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/squad_name_sheet.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/squad_player_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SquadBuilderPage extends StatelessWidget {
  const SquadBuilderPage({required this.squadId, super.key});

  final String squadId;

  @override
  Widget build(BuildContext context) => BlocProvider<SquadBuilderCubit>(
    create: (_) =>
        SquadBuilderCubit(getIt<FcSquadRepository>(), squadId: squadId)..load(),
    child: const _SquadBuilderView(),
  );
}

class _SquadBuilderView extends StatelessWidget {
  const _SquadBuilderView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocConsumer<SquadBuilderCubit, SquadBuilderState>(
      listenWhen: (previous, current) =>
          previous.actionFailure != current.actionFailure &&
          current.actionFailure != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(state.actionFailure!.localizedMessage(l10n)),
            ),
          );
        context.read<SquadBuilderCubit>().clearActionFailure();
      },
      builder: (context, state) {
        final squad = state.squad;

        return AppScaffold(
          appBar: AppAppBar(
            title: squad?.name ?? l10n.squadsSectionTitle,
            subtitle: squad?.formation.displayName,
            actions: <Widget>[
              if (squad != null) ...<Widget>[
                _SaveStatusBadge(isSaving: state.isSaving),
                const SizedBox(width: AppSpacing.sm),
                AppIconButton(
                  icon: Icons.more_horiz,
                  tooltip: l10n.actionMore,
                  variant: AppIconButtonVariant.surface,
                  onPressed: () => _showActions(context, squad, state),
                ),
              ],
            ],
          ),
          body: switch (state.status) {
            SquadBuilderStatus.loading when squad == null => const AppLoading(),
            SquadBuilderStatus.failure when squad == null => AppErrorState(
              title: l10n.errorUnexpected,
              message: state.failure?.localizedMessage(l10n) ?? '',
              retryLabel: l10n.actionRetry,
              onRetry: context.read<SquadBuilderCubit>().load,
            ),
            _ when squad == null => const AppLoading(),
            _ => _Body(squad: squad, state: state),
          },
        );
      },
    );
  }

  Future<void> _showActions(
    BuildContext context,
    FcSquadDetail squad,
    SquadBuilderState state,
  ) async {
    final l10n = context.l10n;
    final cubit = context.read<SquadBuilderCubit>();

    await showAppBottomSheet<void>(
      context: context,
      builder: (sheetContext) => AppBottomSheet(
        title: squad.name,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppButton.secondary(
              label: l10n.squadRenameAction,
              icon: Icons.edit_outlined,
              onPressed: () async {
                Navigator.of(sheetContext).pop();
                final result = await showSquadNameSheet(
                  context: context,
                  title: l10n.squadRenameTitle,
                  initialName: squad.name,
                );
                if (result != null) {
                  await cubit.rename(result.name);
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton.secondary(
              label: l10n.publicProfileShareSquadCta,
              icon: Icons.ios_share,
              onPressed: () {
                Navigator.of(sheetContext).pop();
                context.push(
                  AppRoutes.profileSharingLocation(
                    preselectFcAccountId: squad.fcAccountId,
                    preselectShowSquad: true,
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            if (!squad.isDefault)
              AppButton.secondary(
                label: l10n.squadSetDefaultAction,
                icon: Icons.star_outline,
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  cubit.setDefault();
                },
              ),
            if (squad.hasAnySlotFilled) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              AppButton.ghost(
                label: l10n.squadClearAction,
                icon: Icons.delete_sweep_outlined,
                expanded: true,
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  final confirmed = await showAppDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AppDialog(
                      title: l10n.squadClearConfirmTitle,
                      message: l10n.squadClearConfirmMessage,
                      confirmLabel: l10n.squadClearAction,
                      isDestructive: true,
                      onConfirm: () => Navigator.of(dialogContext).pop(true),
                      cancelLabel: l10n.actionCancel,
                      onCancel: () => Navigator.of(dialogContext).pop(false),
                    ),
                  );
                  if (confirmed ?? false) {
                    await cubit.clearAllSlots();
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Indicador de estado de salvamento no header do builder. A persistência já
/// é por ação (cada toque chama a RPC na hora) -- este badge só reflete o
/// estado da última chamada, nunca cria um segundo "salvar" concorrente.
class _SaveStatusBadge extends StatelessWidget {
  const _SaveStatusBadge({required this.isSaving});

  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (isSaving) {
      return AppBadge(
        label: l10n.squadBuilderSaving,
        tone: AppBadgeTone.info,
        icon: Icons.sync,
      );
    }
    return AppBadge(
      label: l10n.squadBuilderSaved,
      tone: AppBadgeTone.success,
      icon: Icons.check_circle_outline,
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.squad, required this.state});

  final FcSquadDetail squad;
  final SquadBuilderState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SquadBuilderCubit>();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      children: <Widget>[
        Row(
          children: <Widget>[
            AppChip(
              label: squad.formation.displayName,
              icon: Icons.grid_view_outlined,
              onPressed: () => _onChangeFormation(context, squad, state),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (squad.isDefault) AppBadge(label: l10n.squadDefaultBadge),
            const Spacer(),
            Text(
              l10n.squadCompletionLabel(
                squad.startingCount,
                squad.formation.slots.length,
              ),
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            AppBadge(
              label: squad.overall == null
                  ? l10n.squadOverallUnknown
                  : l10n.squadOverallValue(squad.overall!),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Tocar na química abre o detalhe: o número sozinho não diz o que
            // fazer para melhorá-lo.
            InkWell(
              onTap: () =>
                  showSquadChemistrySheet(context: context, squad: squad),
              child: AppBadge(
                label: l10n.squadChemistryValue(squad.chemistry),
                icon: Icons.info_outline,
                tone: squad.chemistry >= 24
                    ? AppBadgeTone.success
                    : squad.chemistry >= 12
                    ? AppBadgeTone.warning
                    : AppBadgeTone.neutral,
              ),
            ),
          ],
        ),
        if (state.pendingMove != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          AppBanner(tone: AppBannerTone.neutral, message: l10n.squadMoveHint),
        ],
        const SizedBox(height: AppSpacing.lg),
        SquadField(
          squad: squad,
          pendingSlotCode: state.pendingMove?.type == SquadSlotType.starting
              ? state.pendingMove?.slotCode
              : null,
          savingSlotCode: state.savingSlot,
          onSlotTap: (slot) => _onSlotTap(context, squad, slot),
          onSlotLongPress: (slot) {
            final card = squad.cardAt(SquadSlotType.starting, slot.slotCode);
            if (card != null) {
              _showSlotActionsSheet(
                context: context,
                type: SquadSlotType.starting,
                slotCode: slot.slotCode,
                positionCode: slot.positionCode,
                card: card,
                slot: squad.slotAt(SquadSlotType.starting, slot.slotCode),
                chemistryRuleVersion: squad.chemistryRuleVersion,
              );
            }
          },
          onSlotDrop: (slot, payload) => cubit.moveOrSwap(
            fromType: payload.type,
            fromSlotCode: payload.slotCode,
            toType: SquadSlotType.starting,
            toSlotCode: slot.slotCode,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _BenchLikeSection(
          title: l10n.squadBenchTitle,
          type: SquadSlotType.bench,
          size: squad.benchSize,
          codeAt: FcSquadDetail.benchCodeAt,
          squad: squad,
          state: state,
        ),
        const SizedBox(height: AppSpacing.xl),
        _BenchLikeSection(
          title: l10n.squadReserveTitle,
          type: SquadSlotType.reserve,
          size: squad.reserveSize,
          codeAt: FcSquadDetail.reserveCodeAt,
          squad: squad,
          state: state,
        ),
        const SizedBox(height: AppSpacing.xl),
        _ManagerSection(squad: squad),
      ],
    );
  }

  Future<void> _onChangeFormation(
    BuildContext context,
    FcSquadDetail squad,
    SquadBuilderState state,
  ) async {
    final l10n = context.l10n;
    final cubit = context.read<SquadBuilderCubit>();
    final code = await showFormationPickerSheet(
      context: context,
      formations: state.formations,
      selectedCode: squad.formation.code,
    );
    if (code == null || code == squad.formation.code) {
      return;
    }
    if (squad.startingCount > 0) {
      if (!context.mounted) {
        return;
      }
      final confirmed = await showAppDialog<bool>(
        context: context,
        builder: (dialogContext) => AppDialog(
          title: l10n.squadFormationChangeConfirmTitle,
          message: l10n.squadFormationChangeConfirmMessage,
          confirmLabel: l10n.squadFormationLabel,
          onConfirm: () => Navigator.of(dialogContext).pop(true),
          cancelLabel: l10n.actionCancel,
          onCancel: () => Navigator.of(dialogContext).pop(false),
        ),
      );
      if (!(confirmed ?? false)) {
        return;
      }
    }
    await cubit.setFormation(code);
  }

  Future<void> _onSlotTap(
    BuildContext context,
    FcSquadDetail squad,
    FormationSlot slot,
  ) async {
    final cubit = context.read<SquadBuilderCubit>();

    // Com um movimento em curso, o toque conclui a troca em vez de abrir o
    // picker -- é o que torna o tap-to-swap previsível.
    if (state.pendingMove != null) {
      await cubit.tapForMove(
        type: SquadSlotType.starting,
        slotCode: slot.slotCode,
      );
      return;
    }

    final card = squad.cardAt(SquadSlotType.starting, slot.slotCode);
    if (card != null) {
      await _showSlotActionsSheet(
        context: context,
        type: SquadSlotType.starting,
        slotCode: slot.slotCode,
        positionCode: slot.positionCode,
        card: card,
        slot: squad.slotAt(SquadSlotType.starting, slot.slotCode),
        chemistryRuleVersion: squad.chemistryRuleVersion,
      );
      return;
    }

    final picked = await showPlayerPickerSheet(
      context: context,
      positionCode: slot.positionCode,
    );
    if (picked != null) {
      await cubit.assignCard(
        type: SquadSlotType.starting,
        slotCode: slot.slotCode,
        playerCardId: picked.id,
      );
    }
  }
}

/// Menu de ações de um slot preenchido -- reusado pelo campo e pelo
/// banco/reservas (item 24: "Ver detalhes" abre o card sheet completo;
/// "Trocar"/"Mover"/"Remover" já existiam desde a Etapa 10).
/// [positionCode] `null` = banco/reserva, o picker de troca não filtra.
Future<void> _showSlotActionsSheet({
  required BuildContext context,
  required SquadSlotType type,
  required String slotCode,
  required PlayerCard card,
  String? positionCode,
  SquadSlot? slot,
  String? chemistryRuleVersion,
}) async {
  final l10n = context.l10n;
  final cubit = context.read<SquadBuilderCubit>();

  await showAppBottomSheet<void>(
    context: context,
    builder: (sheetContext) => AppBottomSheet(
      title: card.displayName,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppButton.secondary(
            label: l10n.squadCardDetailAction,
            icon: Icons.info_outline,
            onPressed: () {
              Navigator.of(sheetContext).pop();
              showPlayerCardDetailSheet(context: context, card: card);
            },
          ),
          // Só titular tem química -- banco e reserva não pontuam, então
          // oferecer a explicação neles seria mentira.
          if (slot != null && type == SquadSlotType.starting) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            AppButton.secondary(
              label: l10n.squadChemistryPlayerTitle,
              icon: Icons.bolt_outlined,
              onPressed: () {
                Navigator.of(sheetContext).pop();
                showPlayerChemistrySheet(
                  context: context,
                  slot: slot,
                  ruleVersion: chemistryRuleVersion,
                );
              },
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppButton.secondary(
            label: l10n.squadSlotChangeAction,
            icon: Icons.swap_horiz,
            onPressed: () async {
              Navigator.of(sheetContext).pop();
              final picked = await showPlayerPickerSheet(
                context: context,
                positionCode: positionCode,
              );
              if (picked != null) {
                await cubit.assignCard(
                  type: type,
                  slotCode: slotCode,
                  playerCardId: picked.id,
                );
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.secondary(
            label: l10n.squadSlotMoveAction,
            icon: Icons.open_with,
            onPressed: () {
              Navigator.of(sheetContext).pop();
              cubit.tapForMove(type: type, slotCode: slotCode);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.ghost(
            label: l10n.squadSlotRemoveAction,
            expanded: true,
            onPressed: () {
              Navigator.of(sheetContext).pop();
              cubit.clearSlot(type: type, slotCode: slotCode);
            },
          ),
        ],
      ),
    ),
  );
}

/// Banco (7) e reservas (5, Etapa 13) usam a MESMA visualização e a mesma
/// lógica -- nenhum dos dois exige posição, nenhum dos dois entra na
/// química (item 34/57). [type]/[size]/[codeAt] são o único ponto de
/// diferença entre as duas seções.
class _BenchLikeSection extends StatelessWidget {
  const _BenchLikeSection({
    required this.title,
    required this.type,
    required this.size,
    required this.codeAt,
    required this.squad,
    required this.state,
  });

  final String title;
  final SquadSlotType type;
  final int size;
  final String Function(int index) codeAt;
  final FcSquadDetail squad;
  final SquadBuilderState state;

  @override
  Widget build(BuildContext context) {
    if (size <= 0) {
      return const SizedBox.shrink();
    }

    final cubit = context.read<SquadBuilderCubit>();
    final filled = size == 0
        ? 0
        : (type == SquadSlotType.bench ? squad.benchCount : squad.reserveCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(title.toUpperCase(), style: context.textStyles.labelSmall),
            const Spacer(),
            Text(
              context.l10n.squadSlotCountLabel(filled, size),
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 72 / SquadPlayerCard.aspectRatio,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: size,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final slotCode = codeAt(index);
              final card = squad.cardAt(type, slotCode);
              return DraggableSquadSlot(
                type: type,
                slotCode: slotCode,
                width: 72,
                card: card,
                state:
                    state.pendingMove?.type == type &&
                        state.pendingMove?.slotCode == slotCode
                    ? SquadPlayerCardState.selected
                    : card == null
                    ? SquadPlayerCardState.empty
                    : SquadPlayerCardState.filled,
                isSaving: state.savingSlot == slotCode,
                onTap: () => _onTap(context, slotCode, card != null),
                onLongPress: card == null
                    ? null
                    : () => _showSlotActionsSheet(
                        context: context,
                        type: type,
                        slotCode: slotCode,
                        card: card,
                      ),
                onAccept: (payload) => cubit.moveOrSwap(
                  fromType: payload.type,
                  fromSlotCode: payload.slotCode,
                  toType: type,
                  toSlotCode: slotCode,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _onTap(
    BuildContext context,
    String slotCode,
    bool occupied,
  ) async {
    final cubit = context.read<SquadBuilderCubit>();

    if (state.pendingMove != null) {
      await cubit.tapForMove(type: type, slotCode: slotCode);
      return;
    }

    if (occupied) {
      await cubit.tapForMove(type: type, slotCode: slotCode);
      return;
    }

    // Banco/reserva não exigem posição: qualquer carta serve.
    final card = await showPlayerPickerSheet(context: context);
    if (card != null) {
      await cubit.assignCard(
        type: type,
        slotCode: slotCode,
        playerCardId: card.id,
      );
    }
  }
}

class _ManagerSection extends StatelessWidget {
  const _ManagerSection({required this.squad});

  final FcSquadDetail squad;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final manager = squad.manager;

    return AppCard(
      onTap: () async {
        final selection = await showManagerPickerSheet(
          context: context,
          currentManager: manager,
          currentLeague: squad.managerLeague,
        );
        if (selection != null && context.mounted) {
          await context.read<SquadBuilderCubit>().setManager(
            managerId: selection.manager?.id,
            managerLeagueId: selection.league?.id,
          );
        }
      },
      child: Row(
        children: <Widget>[
          Icon(Icons.person_outline, color: context.colors.textSecondary),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.squadManagerTitle.toUpperCase(),
                  style: context.textStyles.labelSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  manager?.name ?? l10n.squadManagerNoneTitle,
                  style: context.textStyles.bodyLarge,
                ),
                if (squad.managerLeague != null)
                  Text(
                    squad.managerLeague!.name,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            manager == null ? Icons.add : Icons.chevron_right,
            color: context.colors.textTertiary,
          ),
        ],
      ),
    );
  }
}
