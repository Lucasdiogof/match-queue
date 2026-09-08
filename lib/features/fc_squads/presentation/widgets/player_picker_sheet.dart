import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/fc_squads/domain/repositories/player_card_catalog_repository.dart';
import 'package:fifa_queue/features/fc_squads/presentation/cubit/player_picker_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Escolha de carta para um slot. [positionCode] nulo é banco (sem filtro).
Future<PlayerCard?> showPlayerPickerSheet({
  required BuildContext context,
  String? positionCode,
}) => showAppBottomSheet<PlayerCard>(
  context: context,
  builder: (sheetContext) => BlocProvider<PlayerPickerCubit>(
    create: (_) => PlayerPickerCubit(
      getIt<PlayerCardCatalogRepository>(),
      positionCode: positionCode,
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
            const SizedBox(height: AppSpacing.sm),
            // Deixa explícito que o catálogo ainda é de desenvolvimento --
            // melhor dizer do que deixar parecer dado oficial.
            Text(
              l10n.squadDevCatalogNotice,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.textTertiary,
              ),
            ),
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
          child: ListView.builder(
            itemCount: state.cards.length + (state.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.cards.length) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: AppLoading.inline(),
                );
              }
              return _PlayerRow(
                card: state.cards[index],
                positionCode: context.read<PlayerPickerCubit>().positionCode,
              );
            },
          ),
        );
      },
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.card, this.positionCode});

  final PlayerCard card;
  final String? positionCode;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final tier = positionCode == null
        ? null
        : eligibilityTier(card, positionCode!);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: () => Navigator.of(context).pop(card),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 34,
              child: Text(
                '${card.rating}',
                style: context.textStyles.titleMedium,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    card.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.bodyLarge,
                  ),
                  Text(
                    <String>[
                      card.primaryPosition,
                      ...card.alternativePositions,
                    ].join(' · '),
                    style: context.textStyles.bodySmall?.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (tier != null)
              AppBadge(
                label: switch (tier) {
                  0 => l10n.squadPositionBadgePrimary,
                  1 => l10n.squadPositionBadgeAlternative,
                  _ => l10n.squadPositionBadgeOutOfPosition,
                },
                tone: switch (tier) {
                  0 => AppBadgeTone.success,
                  1 => AppBadgeTone.info,
                  _ => AppBadgeTone.neutral,
                },
              )
            else if (card.cardType != null)
              AppBadge(label: card.cardType!),
          ],
        ),
      ),
    );
  }
}

/// Filtros do picker (item 12 da Etapa 11): rating, liga, clube, nacao.
/// Posicao ja e implicita (o slot filtra por elegibilidade), entao nao
/// aparece aqui de novo.
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

  Future<void> _pickLeague(
    BuildContext context,
    PlayerPickerCubit cubit,
  ) async {
    final leagues = await getIt<PlayerCardCatalogRepository>().getLeagues();
    if (!context.mounted) {
      return;
    }
    final name = await _showNamePickerSheet(
      context,
      title: context.l10n.squadFilterLeagueLabel,
      names: leagues.map((l) => l.name).toList(growable: false),
    );
    if (name != null) {
      cubit.setLeagueName(name);
    }
  }

  Future<void> _pickClub(
    BuildContext context,
    PlayerPickerCubit cubit,
    String? leagueName,
  ) async {
    final clubs = await getIt<PlayerCardCatalogRepository>().getClubs(
      leagueName: leagueName,
    );
    if (!context.mounted) {
      return;
    }
    final name = await _showNamePickerSheet(
      context,
      title: context.l10n.squadFilterClubLabel,
      names: clubs.map((c) => c.name).toList(growable: false),
    );
    if (name != null) {
      cubit.setClubName(name);
    }
  }

  Future<void> _pickNation(
    BuildContext context,
    PlayerPickerCubit cubit,
  ) async {
    final nations = await getIt<PlayerCardCatalogRepository>().getNations();
    if (!context.mounted) {
      return;
    }
    final name = await _showNamePickerSheet(
      context,
      title: context.l10n.squadFilterNationLabel,
      names: nations.map((n) => n.name).toList(growable: false),
    );
    if (name != null) {
      cubit.setNationName(name);
    }
  }

  Future<String?> _showNamePickerSheet(
    BuildContext context, {
    required String title,
    required List<String> names,
  }) => showAppBottomSheet<String>(
    context: context,
    builder: (sheetContext) => AppBottomSheet(
      title: title,
      child: names.isEmpty
          ? Text(sheetContext.l10n.squadPlayerPickerEmpty)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final name in names)
                  AppButton.secondary(
                    label: name,
                    onPressed: () => Navigator.of(sheetContext).pop(name),
                  ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
    ),
  );
}
