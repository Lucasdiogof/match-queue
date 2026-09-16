import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/player_card_detail_sheet.dart';
import 'package:fifa_queue/features/market/presentation/cubit/market_search_cubit.dart';
import 'package:fifa_queue/features/market/presentation/cubit/market_search_state.dart';
import 'package:fifa_queue/features/market/presentation/widgets/market_card_tile.dart';
import 'package:fifa_queue/features/market/presentation/widgets/market_price_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Aba Mercado: busca explicita, nunca lista nada por padrao (pedido do
/// produto). O campo de busca some do estado inicial em diante -- fica
/// sempre visivel, so o corpo abaixo dele muda por status.
class MarketSearchTab extends StatelessWidget {
  const MarketSearchTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppTextField(
            label: l10n.marketSearchFieldLabel,
            hintText: l10n.marketSearchHint,
            prefixIcon: Icons.search,
            onChanged: context.read<MarketSearchCubit>().search,
          ),
        ),
        Expanded(
          child: BlocBuilder<MarketSearchCubit, MarketSearchState>(
            builder: (context, state) => switch (state.status) {
              MarketSearchStatus.initial => AppEmptyState(
                icon: Icons.search,
                title: l10n.marketSearchInitialTitle,
                message: l10n.marketSearchInitialMessage,
                alignment: const Alignment(0, -0.3),
              ),
              MarketSearchStatus.loading => const AppLoading(),
              MarketSearchStatus.noResults => AppEmptyState(
                icon: Icons.search_off,
                title: l10n.marketSearchNoResultsTitle,
                message: l10n.marketSearchNoResultsMessage,
                alignment: const Alignment(0, -0.3),
              ),
              MarketSearchStatus.failure => AppErrorState(
                title: l10n.errorUnexpected,
                message: state.failure?.localizedMessage(l10n) ?? '',
                retryLabel: l10n.actionRetry,
                onRetry: () =>
                    context.read<MarketSearchCubit>().search(state.query),
              ),
              MarketSearchStatus.ready => ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                itemCount: state.cards.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final card = state.cards[index];
                  final isFavorite = state.favoriteCardIds.contains(card.id);
                  return MarketCardTile(
                    card: card,
                    trailing: MarketFavoriteButton(
                      isFavorite: isFavorite,
                      onPressed: () => context
                          .read<MarketSearchCubit>()
                          .toggleFavorite(card.id),
                    ),
                    onTap: () {
                      final searchCubit = context.read<MarketSearchCubit>();
                      showPlayerCardDetailSheet(
                        context: context,
                        card: card,
                        // BlocBuilder (nao um bool fixo) para o icone dentro
                        // da folha refletir a acao na hora, ja que a folha
                        // fica aberta depois do toque em favoritar.
                        footer: BlocBuilder<MarketSearchCubit, MarketSearchState>(
                          bloc: searchCubit,
                          builder: (context, state) => MarketPriceSection(
                            card: card,
                            isFavorite: state.favoriteCardIds.contains(card.id),
                            onToggleFavorite: () =>
                                searchCubit.toggleFavorite(card.id),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            },
          ),
        ),
      ],
    );
  }
}
