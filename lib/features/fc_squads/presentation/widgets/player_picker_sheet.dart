import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/player_card_face.dart';
import 'package:fifa_queue/features/fc_squads/domain/repositories/player_card_catalog_repository.dart';
import 'package:fifa_queue/features/fc_squads/presentation/cubit/player_picker_cubit.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/catalog_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Escolha de carta para um slot. [positionCode] nulo é banco (sem filtro).
/// [excludeCardIds] são cartas já ocupando outro slot do squad atual --
/// nunca oferecidas de novo aqui (gameplay flows refresh, item 4).
Future<PlayerCard?> showPlayerPickerSheet({
  required BuildContext context,
  String? positionCode,
  List<String> excludeCardIds = const <String>[],
}) => showAppBottomSheet<PlayerCard>(
  context: context,
  builder: (sheetContext) => BlocProvider<PlayerPickerCubit>(
    create: (_) => PlayerPickerCubit(
      getIt<PlayerCardCatalogRepository>(),
      positionCode: positionCode,
      excludeCardIds: excludeCardIds,
    )..load(),
    child: _PlayerPickerBody(positionCode: positionCode),
  ),
);

class _PlayerPickerBody extends StatelessWidget {
  const _PlayerPickerBody({this.positionCode});

  final String? positionCode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppBottomSheet(
      title: l10n.squadPlayerPickerTitle,
      subtitle: positionCode,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.55,
        child: Column(
          children: <Widget>[
            AppTextField(
              label: l10n.squadPlayerPickerTitle,
              hintText: l10n.squadPlayerSearchHint,
              prefixIcon: Icons.search,
              onChanged: context.read<PlayerPickerCubit>().search,
            ),
            const SizedBox(height: AppSpacing.sm),
            const _FilterRow(),
            const SizedBox(height: AppSpacing.md),
            const Expanded(child: _PlayerList()),
          ],
        ),
      ),
    );
  }
}

class _PlayerList extends StatelessWidget {
  const _PlayerList();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<PlayerPickerCubit, PlayerPickerState>(
      builder: (context, state) {
        if (state.status == PlayerPickerStatus.loading && state.cards.isEmpty) {
          return const AppLoading();
        }

        if (state.status == PlayerPickerStatus.failure) {
          return AppErrorState(
            title: l10n.errorUnexpected,
            message: state.failure?.localizedMessage(l10n) ?? '',
            retryLabel: l10n.actionRetry,
            onRetry: context.read<PlayerPickerCubit>().load,
          );
        }

        if (state.cards.isEmpty) {
          return Center(
            child: Text(
              l10n.squadPlayerPickerEmpty,
              style: context.textStyles.bodyMedium,
            ),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 120) {
              context.read<PlayerPickerCubit>().loadMore();
            }
            return false;
          },
          // Grade de cartas em vez de linhas: o jogador reconhece uma carta
          // pelo conjunto (rating, posicao, atributos), nao lendo um nome
          // numa lista.
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 158,
              childAspectRatio: 0.72,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
            ),
            itemCount: state.cards.length + (state.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.cards.length) {
                return const Center(child: AppLoading.inline());
              }
              final card = state.cards[index];
              final positionCode = context
                  .read<PlayerPickerCubit>()
                  .positionCode;
              return PlayerCardFace(
                card: card,
                eligibility: positionCode == null
                    ? null
                    : eligibilityTier(card, positionCode),
                onTap: () => Navigator.of(context).pop(card),
              );
            },
          ),
        );
      },
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow();

  static const List<int?> _ratingOptions = <int?>[null, 75, 80, 85, 90];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<PlayerPickerCubit, PlayerPickerState>(
      builder: (context, state) {
        final cubit = context.read<PlayerPickerCubit>();
        return SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              if (cubit.positionCode != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: AppChip(
                    label: l10n.squadFilterCompatibleLabel,
                    icon: Icons.check_circle_outline,
                    isSelected: state.compatibleOnly,
                    onPressed: () =>
                        cubit.setCompatibleOnly(!state.compatibleOnly),
                  ),
                ),
              for (final rating in _ratingOptions)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: AppChip(
                    label: rating == null ? l10n.historyStatusAll : '$rating+',
                    isSelected: state.minRating == rating,
                    onPressed: () => cubit.setMinRating(rating),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: AppChip(
                  label: state.leagueName ?? l10n.squadFilterLeagueLabel,
                  icon: Icons.emoji_events_outlined,
                  isSelected: state.leagueName != null,
                  onPressed: () => _pickLeague(context, cubit),
                ),
              ),
              if (state.leagueName != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: AppChip(
                    label: state.clubName ?? l10n.squadFilterClubLabel,
                    icon: Icons.shield_outlined,
                    isSelected: state.clubName != null,
                    onPressed: () =>
                        _pickClub(context, cubit, state.leagueName),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: AppChip(
                  label: state.nationName ?? l10n.squadFilterNationLabel,
                  icon: Icons.flag_outlined,
                  isSelected: state.nationName != null,
                  onPressed: () => _pickNation(context, cubit),
                ),
              ),
              if (state.hasActiveFilters)
                AppChip(
                  label: l10n.actionCancel,
                  icon: Icons.close,
                  onPressed: cubit.clearFilters,
                ),
            ],
          ),
        );
      },
    );
  }

  // Liga fica flat (so ~57 no catalogo real -- nao justifica agrupamento
  // alfabetico), so com o overflow de scroll corrigido (item 7/9).
  Future<void> _pickLeague(
    BuildContext context,
    PlayerPickerCubit cubit,
  ) async {
    final leagues = await getIt<PlayerCardCatalogRepository>().getLeagues();
    if (!context.mounted) {
      return;
    }
    final name = await showFlatCatalogPickerSheet(
      context: context,
      title: context.l10n.squadFilterLeagueLabel,
      names: leagues.map((l) => l.name).toList(growable: false),
    );
    if (name != null) {
      cubit.setLeagueName(name);
    }
  }

  // Clube e hierarquico (item 10): faixa alfabetica de Liga -> Liga ->
  // Clubes daquela liga. ~572-646 clubes no catalogo real nunca cabem numa
  // lista plana.
  Future<void> _pickClub(
    BuildContext context,
    PlayerPickerCubit cubit,
    String? leagueName,
  ) async {
    var effectiveLeagueName = leagueName;
    if (effectiveLeagueName == null) {
      final leagues = await getIt<PlayerCardCatalogRepository>().getLeagues();
      if (!context.mounted) {
        return;
      }
      effectiveLeagueName = await showAlphabeticalPickerSheet(
        context: context,
        title: context.l10n.squadFilterLeagueLabel,
        names: leagues.map((l) => l.name).toList(growable: false),
      );
      if (effectiveLeagueName == null || !context.mounted) {
        return;
      }
    }
    final clubs = await getIt<PlayerCardCatalogRepository>().getClubs(
      leagueName: effectiveLeagueName,
    );
    if (!context.mounted) {
      return;
    }
    final name = await showFlatCatalogPickerSheet(
      context: context,
      title: context.l10n.squadFilterClubLabel,
      names: clubs.map((c) => c.name).toList(growable: false),
    );
    if (name != null) {
      cubit.setClubName(name);
    }
  }

  // Nacao e agrupada por faixa alfabetica (item 8): ~157 no catalogo real.
  Future<void> _pickNation(
    BuildContext context,
    PlayerPickerCubit cubit,
  ) async {
    final nations = await getIt<PlayerCardCatalogRepository>().getNations();
    if (!context.mounted) {
      return;
    }
    final name = await showAlphabeticalPickerSheet(
      context: context,
      title: context.l10n.squadFilterNationLabel,
      names: nations.map((n) => n.name).toList(growable: false),
    );
    if (name != null) {
      cubit.setNationName(name);
    }
  }
}
