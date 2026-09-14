import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_manager.dart';
import 'package:fifa_queue/features/fc_squads/domain/repositories/player_card_catalog_repository.dart';
import 'package:fifa_queue/features/fc_squads/presentation/cubit/manager_picker_cubit.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/catalog_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManagerSelection {
  const ManagerSelection({this.manager, this.league});

  final FcManager? manager;
  final FcLeague? league;
}

/// País -> técnico -> liga, cada passo na SUA PRÓPRIA folha.
///
/// Antes era tudo numa lista só (chips de país, depois chips de técnico logo
/// abaixo) -- escolher o país não deixava óbvio que era preciso rolar pra
/// baixo pra ver os técnicos daquele país, que ficavam fora da tela. Agora
/// escolher o país abre direto a folha de técnicos daquele país (2 folhas em
/// sequência), e a folha principal só mostra o resumo com 3 linhas
/// tocáveis -- qualquer uma pode ser reaberta pra trocar a escolha.
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

  Future<void> _pickNation(BuildContext context) async {
    final cubit = context.read<ManagerPickerCubit>();
    final nations = cubit.state.nations;
    final pickedName = await showAlphabeticalPickerSheet(
      context: context,
      title: context.l10n.squadManagerNationLabel,
      names: nations.map((n) => n.name).toList(growable: false),
    );
    if (pickedName == null || !context.mounted) {
      return;
    }
    final nation = nations.firstWhere((n) => n.name == pickedName);
    // So abre a folha de tecnicos DEPOIS do load terminar -- sem isso a
    // lista abriria vazia e pareceria um bug (a lacuna original: pais
    // selecionado, mas tecnico nenhum a vista).
    await cubit.selectNation(nation);
    if (context.mounted) {
      await _pickManager(context);
    }
  }

  Future<void> _pickManager(BuildContext context) async {
    final cubit = context.read<ManagerPickerCubit>();
    final managers = cubit.state.managers;
    final pickedName = await showFlatCatalogPickerSheet(
      context: context,
      title: context.l10n.squadManagerTitle,
      names: managers.map((m) => m.name).toList(growable: false),
    );
    if (pickedName == null || !context.mounted) {
      return;
    }
    cubit.selectManager(managers.firstWhere((m) => m.name == pickedName));
  }

  Future<void> _pickLeague(BuildContext context) async {
    final cubit = context.read<ManagerPickerCubit>();
    final leagues = cubit.state.leagues;
    final pickedName = await showFlatCatalogPickerSheet(
      context: context,
      title: context.l10n.squadManagerLeagueLabel,
      names: leagues.map((l) => l.name).toList(growable: false),
    );
    if (pickedName == null || !context.mounted) {
      return;
    }
    cubit.selectLeague(leagues.firstWhere((l) => l.name == pickedName));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<ManagerPickerCubit, ManagerPickerState>(
      builder: (context, state) {
        if (state.status == ManagerPickerStatus.loading) {
          return AppBottomSheet(
            title: l10n.squadManagerTitle,
            child: const SizedBox(height: 160, child: AppLoading()),
          );
        }

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _PickerRow(
                label: l10n.squadManagerNationLabel,
                value: state.selectedNation?.name,
                placeholder: l10n.squadManagerEmpty,
                onTap: () => _pickNation(context),
              ),
              const SizedBox(height: AppSpacing.sm),
              _PickerRow(
                label: l10n.squadManagerTitle,
                value: state.selectedManager?.name,
                placeholder: l10n.squadManagerPickNationFirst,
                // So habilita depois de ter pais (e, por tabela, tecnicos ja
                // carregados) -- reabrir aqui reusa a lista ja carregada,
                // sem novo fetch.
                onTap: state.selectedNation == null || state.isLoadingManagers
                    ? null
                    : () => _pickManager(context),
                isLoading: state.isLoadingManagers,
              ),
              if (state.canPickLeague) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                _PickerRow(
                  label: l10n.squadManagerLeagueLabel,
                  value: state.selectedLeague?.name,
                  placeholder: l10n.squadManagerLeagueLabel,
                  onTap: () => _pickLeague(context),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Linha tocável de um passo do fluxo: rótulo + valor escolhido (ou
/// placeholder) + chevron. Mesma leitura visual em toda a folha, então fica
/// óbvio que os três passos funcionam do mesmo jeito.
class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.isLoading = false,
  });

  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: colors.textTertiary,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  value ?? placeholder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleSmall?.copyWith(
                    color: value == null
                        ? colors.textSecondary
                        : colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const AppLoading.inline()
          else
            Icon(
              Icons.chevron_right,
              size: AppSizing.iconMd,
              color: onTap == null ? colors.textTertiary : colors.textPrimary,
            ),
        ],
      ),
    );
  }
}
