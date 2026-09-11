import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/formation.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/lineup_draft.dart';
import 'package:fifa_queue/features/fc_squads/domain/repositories/fc_squad_repository.dart';
import 'package:fifa_queue/features/fc_squads/presentation/cubit/squad_builder_cubit.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/formation_picker_sheet.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/lineup_manager_slot.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/lineup_share_sheet.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/player_picker_sheet.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/squad_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Editor do Elenco.
///
/// Tudo aqui e rascunho: escolher jogador, trocar formacao e definir tecnico
/// mudam apenas o estado local. So o botao Salvar persiste, e numa transacao
/// unica. Sair com alteracoes pendentes pede confirmacao.
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

  Future<bool> _confirmDiscard(BuildContext context) async {
    final l10n = context.l10n;
    return showAppConfirm(
      context: context,
      title: l10n.squadDiscardTitle,
      message: l10n.squadDiscardMessage,
      cancelLabel: l10n.squadDiscardKeep,
      confirmLabel: l10n.squadDiscardConfirm,
      isDestructive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocConsumer<SquadBuilderCubit, SquadBuilderState>(
      listenWhen: (previous, current) =>
          previous.saveFailure != current.saveFailure ||
          previous.droppedByFormationChange != current.droppedByFormationChange,
      listener: (context, state) {
        final dropped = state.droppedByFormationChange;
        if (dropped.isNotEmpty) {
          // Aviso, nao deposito: quem saiu nao foi para banco nenhum.
          showAppSnack(
            context,
            message: l10n.squadFormationDroppedPlayers(
              dropped.length,
              dropped.map((c) => c.displayName).take(3).join(', '),
            ),
          );
        }
        final failure = state.saveFailure;
        if (failure != null && !state.hasConflict) {
          showAppSnack(
            context,
            message: failure.localizedMessage(l10n),
            isError: true,
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<SquadBuilderCubit>();
        final draft = state.draft;

        return PopScope(
          // Só intercepta quando ha o que perder. Sem alteracoes, voltar e
          // voltar -- inclusive por gesto e pelo back do Android, porque o
          // PopScope cobre os tres caminhos sem bloquear o swipe global.
          canPop: !state.isDirty,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop || !context.mounted) {
              return;
            }
            final navigator = Navigator.of(context);
            if (await _confirmDiscard(context)) {
              navigator.pop();
            }
          },
          child: AppScaffold(
            appBar: AppAppBar(
              title: l10n.squadLabel,
              actions: <Widget>[
                if (draft != null)
                  AppIconButton(
                    icon: Icons.ios_share,
                    tooltip: l10n.squadShareAction,
                    onPressed: () => _share(context, state),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: _SaveButton(state: state),
                ),
              ],
            ),
            body: switch (state.status) {
              SquadBuilderStatus.loading => const AppLoading(),
              SquadBuilderStatus.failure => AppErrorState(
                title: l10n.errorUnexpected,
                message:
                    state.failure?.localizedMessage(l10n) ?? l10n.errorUnexpected,
                retryLabel: l10n.actionRetry,
                onRetry: cubit.load,
              ),
              SquadBuilderStatus.ready when draft != null => _Body(
                state: state,
                draft: draft,
              ),
              _ => const AppLoading(),
            },
          ),
        );
      },
    );
  }

  void _share(BuildContext context, SquadBuilderState state) {
    // Compartilha o que esta na tela, salvo ou nao -- e uma montagem visual,
    // nao uma publicacao. E nao passa por Privacidade: isso mora no Perfil.
    showLineupShareSheet(context: context, state: state);
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.state});

  final SquadBuilderState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SquadBuilderCubit>();

    if (state.isSaving) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Center(child: AppLoading.inline()),
      );
    }
    return TextButton(
      // Desabilitado sem alteracao e durante conflito: salvar por cima de
      // uma versao que mudou em outro aparelho nao e uma opcao oferecida.
      onPressed: state.canSave ? cubit.save : null,
      child: Text(
        l10n.squadSaveAction,
        style: context.textStyles.labelLarge?.copyWith(
          color: state.canSave
              ? context.colors.accent
              : context.colors.textTertiary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.draft});

  final SquadBuilderState state;
  final LineupDraft draft;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SquadBuilderCubit>();

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: <Widget>[
        if (state.hasConflict) _ConflictBanner(onReload: cubit.reloadAfterConflict),
        _SummaryRow(state: state, draft: draft),
        const SizedBox(height: AppSpacing.lg),
        SquadField(
          formation: draft.formation,
          starters: draft.starters,
          onSlotTap: (slot) => _pickPlayer(context, slot),
          onSlotLongPress: (slot) => cubit.clearSlot(slot.slotCode),
          onSlotDrop: (slot, payload) {
            final card = draft.starters[payload.slotCode];
            if (card != null) {
              cubit.assignCard(slotCode: slot.slotCode, card: card);
            }
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        LineupManagerSlot(draft: draft),
      ],
    );
  }

  Future<void> _pickPlayer(BuildContext context, FormationSlot slot) async {
    final cubit = context.read<SquadBuilderCubit>();
    final card = await showPlayerPickerSheet(
      context: context,
      positionCode: slot.positionCode,
    );
    if (card != null) {
      cubit.assignCard(slotCode: slot.slotCode, card: card);
    }
  }
}

/// Formacao, overall e quimica. Sem "Padrao" e sem contador de titulares --
/// quem esta olhando o campo ja sabe quantos colocou.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.state, required this.draft});

  final SquadBuilderState state;
  final LineupDraft draft;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SquadBuilderCubit>();

    return AppCard(
      accent: AppCardAccent.left,
      child: Row(
        children: <Widget>[
          Expanded(
            child: _Metric(
              label: l10n.squadFormationLabel,
              value: draft.formation.code,
              onTap: () async {
                final code = await showFormationPickerSheet(
                  context: context,
                  formations: state.formations,
                  selectedCode: draft.formation.code,
                );
                if (code != null) {
                  cubit.setFormation(code);
                }
              },
            ),
          ),
          Expanded(
            child: _Metric(
              label: l10n.squadOverallLabel,
              // Local e imediato: media das notas dos titulares.
              value: draft.overall?.toString() ?? '--',
            ),
          ),
          Expanded(
            child: _Metric(
              label: l10n.squadChemistryLabel,
              value: state.chemistry == null ? '--' : '${state.chemistry}/33',
              // O valor continua visivel enquanto recalcula, mas dito como
              // "recalculando" -- nao como se ja correspondesse ao rascunho.
              isStale: state.previewStatus == LineupPreviewStatus.updating,
              hasError: state.previewStatus == LineupPreviewStatus.failure,
              onTap: state.previewStatus == LineupPreviewStatus.failure
                  ? cubit.retryPreview
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.onTap,
    this.isStale = false,
    this.hasError = false,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool isStale;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.borderSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Flexible(
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.labelSmall?.copyWith(
                      color: colors.textTertiary,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                if (isStale) ...<Widget>[
                  const SizedBox(width: AppSpacing.xxs),
                  SizedBox(
                    width: 8,
                    height: 8,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: colors.textTertiary,
                    ),
                  ),
                ],
                if (hasError) ...<Widget>[
                  const SizedBox(width: AppSpacing.xxs),
                  Icon(Icons.refresh, size: 12, color: colors.warning),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: onTap == null ? colors.textPrimary : colors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConflictBanner extends StatelessWidget {
  const _ConflictBanner({required this.onReload});

  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppCard(
        accent: AppCardAccent.left,
        accentColor: context.colors.warning,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.errorSquadEditConflict,
              style: context.textStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton.secondary(
              label: l10n.squadReloadAction,
              icon: Icons.refresh,
              onPressed: onReload,
            ),
          ],
        ),
      ),
    );
  }
}
