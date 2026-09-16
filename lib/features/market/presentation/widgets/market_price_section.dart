import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/market/domain/entities/market_price.dart';
import 'package:fifa_queue/features/market/domain/repositories/market_price_repository.dart';
import 'package:fifa_queue/features/market/presentation/cubit/market_price_cubit.dart';
import 'package:fifa_queue/features/market/presentation/cubit/market_price_state.dart';
import 'package:fifa_queue/features/market/presentation/widgets/market_card_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Secao de preco do detalhe da carta (feature Mercado): preco atual,
/// minimo/maximo, ultima atualizacao, historico e plataforma -- so o que a
/// fonte realmente devolver, nunca um campo inventado -- mais o toggle de
/// favorito. Cria seu proprio [MarketPriceCubit] (mesmo padrao de
/// showPlayerPickerSheet: pegar a dependencia via `getIt` direto na folha,
/// nao depender de um Provider ancestral sobreviver ate o bottom sheet).
class MarketPriceSection extends StatelessWidget {
  const MarketPriceSection({
    required this.card,
    required this.isFavorite,
    required this.onToggleFavorite,
    super.key,
  });

  final PlayerCard card;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) => BlocProvider<MarketPriceCubit>(
    create: (_) => MarketPriceCubit(getIt<MarketPriceRepository>())..load(card),
    child: _MarketPriceBody(
      isFavorite: isFavorite,
      onToggleFavorite: onToggleFavorite,
    ),
  );
}

class _MarketPriceBody extends StatelessWidget {
  const _MarketPriceBody({
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              l10n.marketPriceSectionTitle.toUpperCase(),
              style: context.textStyles.labelSmall,
            ),
            const Spacer(),
            MarketFavoriteButton(
              isFavorite: isFavorite,
              onPressed: onToggleFavorite,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        BlocBuilder<MarketPriceCubit, MarketPriceState>(
          builder: (context, state) => switch (state.status) {
            MarketPriceStatus.loading => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: AppLoading.inline()),
            ),
            MarketPriceStatus.failure => Text(
              l10n.marketPriceUnavailableMessage,
              style: context.textStyles.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            MarketPriceStatus.unavailable => Text(
              l10n.marketPriceUnavailableMessage,
              style: context.textStyles.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            MarketPriceStatus.available => _PriceDetails(
              price: state.price!,
            ),
          },
        ),
      ],
    );
  }
}

class _PriceDetails extends StatelessWidget {
  const _PriceDetails({required this.price});

  final MarketPrice price;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final formatter = NumberFormat.decimalPattern(l10n.localeName);

    String money(int? value) => value == null ? '—' : formatter.format(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            _PriceStat(
              label: l10n.marketPriceCurrentLabel,
              value: money(price.currentPrice),
              emphasize: true,
            ),
            if (price.minPrice != null)
              _PriceStat(
                label: l10n.marketPriceMinLabel,
                value: money(price.minPrice),
              ),
            if (price.maxPrice != null)
              _PriceStat(
                label: l10n.marketPriceMaxLabel,
                value: money(price.maxPrice),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.marketPriceUpdatedAtLabel(
            DateFormat.yMd(l10n.localeName).add_Hm().format(price.updatedAt),
          ),
          style: context.textStyles.bodySmall?.copyWith(
            color: colors.textTertiary,
          ),
        ),
        if (price.platform != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.marketPricePlatformLabel(price.platform!),
            style: context.textStyles.bodySmall?.copyWith(
              color: colors.textTertiary,
            ),
          ),
        ],
        if (price.hasHistory) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.marketPriceHistoryLabel,
            style: context.textStyles.labelSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final point in price.history)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    DateFormat.yMd(l10n.localeName).format(point.observedAt),
                    style: context.textStyles.bodySmall,
                  ),
                  Text(money(point.price), style: context.textStyles.bodySmall),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _PriceStat extends StatelessWidget {
  const _PriceStat({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        label,
        style: context.textStyles.labelSmall?.copyWith(
          color: context.colors.textTertiary,
        ),
      ),
      Text(
        value,
        style: emphasize
            ? context.textStyles.titleLarge
            : context.textStyles.titleMedium,
      ),
    ],
  );
}
