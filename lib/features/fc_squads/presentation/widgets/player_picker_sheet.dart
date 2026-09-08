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
              return _PlayerRow(card: state.cards[index]);
            },
          ),
        );
      },
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.card});

  final PlayerCard card;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
            if (card.cardType != null) AppBadge(label: card.cardType!),
          ],
        ),
      ),
    );
  }
}
