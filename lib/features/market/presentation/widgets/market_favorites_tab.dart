import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/player_card_detail_sheet.dart';
import 'package:fifa_queue/features/market/presentation/cubit/market_favorites_cubit.dart';
import 'package:fifa_queue/features/market/presentation/cubit/market_favorites_state.dart';
import 'package:fifa_queue/features/market/presentation/widgets/market_card_tile.dart';
import 'package:fifa_queue/features/market/presentation/widgets/market_price_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Aba Favoritos: watchlist pessoal, sempre carregada (diferente da aba
/// Mercado, que nunca lista nada sem busca -- aqui a lista JA E o que o
/// usuario pediu pra ver).
class MarketFavoritesTab extends StatelessWidget {
  const MarketFavoritesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<MarketFavoritesCubit, MarketFavoritesState>(
      builder: (context, state) => switch (state.status) {
        MarketFavoritesStatus.loading => const AppLoading(),
        MarketFavoritesStatus.failure => AppErrorState(
          title: l10n.errorUnexpected,
          message: state.failure?.localizedMessage(l10n) ?? '',
          retryLabel: l10n.actionRetry,
          onRetry: () => context.read<MarketFavoritesCubit>().load(),
        ),
        MarketFavoritesStatus.empty => AppEmptyState(
          icon: Icons.star_border,
          title: l10n.marketFavoritesEmptyTitle,
          message: l10n.marketFavoritesEmptyMessage,
          alignment: const Alignment(0, -0.3),
        ),
        MarketFavoritesStatus.ready => RefreshIndicator(
          onRefresh: () => context.read<MarketFavoritesCubit>().load(),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            itemCount: state.cards.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final card = state.cards[index];
              return MarketCardTile(
                card: card,
                trailing: MarketFavoriteButton(
                  isFavorite: true,
                  onPressed: () => context
                      .read<MarketFavoritesCubit>()
                      .removeFavorite(card.id),
                ),
                onTap: () {
                  final favoritesCubit = context.read<MarketFavoritesCubit>();
                  showPlayerCardDetailSheet(
                    context: context,
                    card: card,
                    footer: MarketPriceSection(
                      card: card,
                      isFavorite: true,
                      onToggleFavorite: () =>
                          favoritesCubit.removeFavorite(card.id),
                    ),
                  );
                },
              );
            },
          ),
        ),
      },
    );
  }
}
