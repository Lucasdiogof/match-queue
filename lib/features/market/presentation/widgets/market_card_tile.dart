import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/player_card_face.dart';
import 'package:flutter/material.dart';

/// Linha de carta reusada pela busca do Mercado e pela aba Favoritos: imagem,
/// jogador, overall, posicao, tipo/versao. [trailing] e o unico ponto que
/// difere entre os dois usos (icone de favorito vs. atualizacao/variacao).
class MarketCardTile extends StatelessWidget {
  const MarketCardTile({
    required this.card,
    required this.trailing,
    this.onTap,
    super.key,
  });

  final PlayerCard card;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          // PlayerCardFace ja se dimensiona sozinho (AspectRatio interno) a
          // partir da largura recebida -- so precisa de uma largura, nao de
          // outro AspectRatio por fora.
          SizedBox(width: 56, child: PlayerCardFace(card: card)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  card.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: <Widget>[
                    AppBadge(
                      label:
                          '${l10n.squadCardDetailRatingLabel} ${card.rating}',
                    ),
                    AppBadge(label: card.primaryPosition),
                    if (card.cardType != null) AppBadge(label: card.cardType!),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          trailing,
        ],
      ),
    );
  }
}

/// Icone de favorito reusado no tile e no detalhe -- estrela preenchida
/// quando ja favoritado, contorno quando nao.
class MarketFavoriteButton extends StatelessWidget {
  const MarketFavoriteButton({
    required this.isFavorite,
    required this.onPressed,
    super.key,
  });

  final bool isFavorite;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Preenchido vs contorno ja diferencia favoritado/nao -- AppIconButton
    // nao expoe cor customizada, e o icone sozinho ja e um sinal claro sem
    // precisar de uma (mesmo padrao de outros toggles booleanos do app).
    return AppIconButton(
      icon: isFavorite ? Icons.star : Icons.star_border,
      tooltip: isFavorite
          ? l10n.marketFavoriteRemoveAction
          : l10n.marketFavoriteAddAction,
      onPressed: onPressed,
    );
  }
}
