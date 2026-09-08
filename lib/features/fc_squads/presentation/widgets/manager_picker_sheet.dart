import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_manager.dart';
import 'package:fifa_queue/features/fc_squads/domain/repositories/player_card_catalog_repository.dart';
import 'package:fifa_queue/features/fc_squads/presentation/cubit/manager_picker_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManagerSelection {
  const ManagerSelection({this.manager, this.league});

  final FcManager? manager;
  final FcLeague? league;
}

/// País -> técnico -> liga. A liga é do SQUAD, não do técnico, por isso é
/// escolhida aqui e não vem colada nele.
Future<ManagerSelection?> showManagerPickerSheet({
  required BuildContext context,
  FcManager? currentManager,
  FcLeague? currentLeague,
}) => showAppBottomSheet<ManagerSelection>(
  context: context,
  builder: (sheetContext) => BlocProvider<ManagerPickerCubit>(
    create: (_) => ManagerPickerCubit(
      getIt<PlayerCardCatalogRepository>(),
      initialManager: currentManager,
      initialLeague: currentLeague,
    )..load(),
    child: const _ManagerPickerBody(),
  ),
);

class _ManagerPickerBody extends StatelessWidget {
  const _ManagerPickerBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<ManagerPickerCubit, ManagerPickerState>(
      builder: (context, state) {
        final cubit = context.read<ManagerPickerCubit>();

        return AppBottomSheet(
          title: l10n.squadManagerTitle,
          actions: <Widget>[
            AppButton(
              label: l10n.actionSave,
              onPressed: state.selectedManager == null
                  ? null
                  : () => Navigator.of(context).pop(
                      ManagerSelection(
                        manager: state.selectedManager,
                        league: state.selectedLeague,
                      ),
                    ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton.ghost(
              label: l10n.squadManagerRemoveAction,
              expanded: true,
              onPressed: () =>
                  Navigator.of(context).pop(const ManagerSelection()),
            ),
          ],
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.5,
            child: state.status == ManagerPickerStatus.loading
                ? const AppLoading()
                : ListView(
                    children: <Widget>[
                      _SectionLabel(text: l10n.squadManagerNationLabel),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: <Widget>[
                          for (final nation in state.nations)
                            AppChip(
                              label: nation.name,
                              isSelected: state.selectedNation?.id == nation.id,
                              onPressed: () => cubit.selectNation(nation),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _SectionLabel(text: l10n.squadManagerTitle),
                      if (state.selectedNation == null)
                        Text(
                          l10n.squadManagerPickNationFirst,
                          style: context.textStyles.bodySmall,
                        )
                      else if (state.isLoadingManagers)
                        const SizedBox(height: 64, child: AppLoading.inline())
                      else
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: <Widget>[
                            for (final manager in state.managers)
                              AppChip(
                                label: manager.name,
                                isSelected:
                                    state.selectedManager?.id == manager.id,
                                onPressed: () => cubit.selectManager(manager),
                              ),
                          ],
                        ),
                      // A liga só aparece depois do técnico escolhido: antes
                      // disso ela não teria a que se aplicar.
                      if (state.canPickLeague) ...<Widget>[
                        const SizedBox(height: AppSpacing.xl),
                        _SectionLabel(text: l10n.squadManagerLeagueLabel),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: <Widget>[
                            for (final league in state.leagues)
                              AppChip(
                                label: league.name,
                                isSelected:
                                    state.selectedLeague?.id == league.id,
                                onPressed: () => cubit.selectLeague(league),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Text(text.toUpperCase(), style: context.textStyles.labelSmall),
  );
}
