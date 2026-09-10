import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:flutter/material.dart';

/// A carta de um jogador, no formato de carta mesmo -- rating e posicao no
/// topo, nome, e a faixa de atributos embaixo.
///
/// Deliberadamente NAO e uma copia da arte da EA: o desenho aqui e do
/// produto (tokens do design system, faixa por tier de rating), nao o
/// gradiente dourado deles. O app ja carrega aviso de nao afiliacao e clonar
/// a identidade visual seria andar na direcao contraria.
///
/// Sem foto por decisao de DADO, nao de layout: o pacote FC27 nao traz
/// nenhuma URL de imagem -- nem rosto, nem escudo, nem bandeira. O monograma
/// ocupa esse espaco e some sozinho no dia em que [PlayerCard.playerImageUrl]
/// vier preenchido.
class PlayerCardFace extends StatelessWidget {
  const PlayerCardFace({
    required this.card,
    this.onTap,
    this.isSelected = false,
    this.eligibility,
    super.key,
  });

  final PlayerCard card;
  final VoidCallback? onTap;
  final bool isSelected;

  /// 0 = posicao principal, 1 = alternativa, 2 = fora de posicao. Null
  /// quando o picker nao foi aberto por um slot.
  final int? eligibility;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tier = _CardTier.of(card.rating, colors);

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 0.72,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[tier.top, tier.bottom],
            ),
            border: Border.all(
              color: isSelected ? colors.textPrimary : tier.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _Header(card: card, tier: tier, eligibility: eligibility),
                Expanded(
                  child: _Monogram(card: card, tier: tier),
                ),
                Text(
                  card.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: context.textStyles.labelMedium?.copyWith(
                    color: tier.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Divider(height: 1, color: tier.border),
                const SizedBox(height: AppSpacing.xs),
                _Attributes(card: card, tier: tier),
                if (card.clubName != null ||
                    card.nationName != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    <String>[
                      if (card.nationName != null) card.nationName!,
                      if (card.clubName != null) card.clubName!,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: context.textStyles.labelSmall?.copyWith(
                      color: tier.inkFaded,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.card,
    required this.tier,
    required this.eligibility,
  });

  final PlayerCard card;
  final _CardTier tier;
  final int? eligibility;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '${card.rating}',
            style: context.textStyles.headlineSmall?.copyWith(
              color: tier.ink,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                card.primaryPosition,
                style: context.textStyles.labelSmall?.copyWith(color: tier.ink),
              ),
              // Elegibilidade para o slot que abriu o picker. Sem slot
              // (explorar catalogo) nao existe marcador nenhum.
              if (eligibility != null) ...<Widget>[
                const SizedBox(width: AppSpacing.xxs),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: switch (eligibility!) {
                      0 => context.colors.success,
                      1 => context.colors.info,
                      _ => context.colors.textTertiary,
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      const Spacer(),
      // Perna ruim e dribles so aparecem quando o dado existe -- carta sem
      // eles nao ganha um "0" inventado.
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (card.skillMoves != null)
            Text(
              '${card.skillMoves}★',
              style: context.textStyles.labelSmall?.copyWith(color: tier.ink),
            ),
          if (card.weakFoot != null)
            Text(
              '${card.weakFoot}◆',
              style: context.textStyles.labelSmall?.copyWith(
                color: tier.inkFaded,
              ),
            ),
        ],
      ),
    ],
  );
}

class _Monogram extends StatelessWidget {
  const _Monogram({required this.card, required this.tier});

  final PlayerCard card;
  final _CardTier tier;

  @override
  Widget build(BuildContext context) {
    final url = card.playerImageUrl;
    if (url != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _initials(context),
        ),
      );
    }
    return _initials(context);
  }

  Widget _initials(BuildContext context) => FittedBox(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Text(
        _monogramOf(card.displayName),
        style: context.textStyles.headlineSmall?.copyWith(
          color: tier.inkFaded,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );

  static String _monogramOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

/// Goleiro tem os proprios seis atributos -- mostrar PAC/SHO num goleiro
/// seria mostrar campo vazio.
class _Attributes extends StatelessWidget {
  const _Attributes({required this.card, required this.tier});

  final PlayerCard card;
  final _CardTier tier;

  @override
  Widget build(BuildContext context) {
    final entries = card.isGoalkeeper
        ? <(String, int?)>[
            ('DIV', card.gkDiving),
            ('HAN', card.gkHandling),
            ('KIC', card.gkKicking),
            ('REF', card.gkReflexes),
            ('SPD', card.gkSpeed),
            ('POS', card.gkPositioning),
          ]
        : <(String, int?)>[
            ('PAC', card.pace),
            ('SHO', card.shooting),
            ('PAS', card.passing),
            ('DRI', card.dribbling),
            ('DEF', card.defending),
            ('PHY', card.physical),
          ];

    if (entries.every((entry) => entry.$2 == null)) {
      return const SizedBox.shrink();
    }

    // Duas linhas de tres, nao seis colunas: com seis, cada rotulo fica
    // com menos largura do que "PAC" precisa e quebra no meio da palavra.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _AttributeRow(entries: entries.sublist(0, 3), tier: tier),
        const SizedBox(height: AppSpacing.xxs),
        _AttributeRow(entries: entries.sublist(3), tier: tier),
      ],
    );
  }
}

class _AttributeRow extends StatelessWidget {
  const _AttributeRow({required this.entries, required this.tier});

  final List<(String, int?)> entries;
  final _CardTier tier;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      for (final entry in entries)
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                entry.$2 == null ? '-' : '${entry.$2}',
                maxLines: 1,
                style: context.textStyles.labelSmall?.copyWith(
                  color: tier.ink,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                entry.$1,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: context.textStyles.labelSmall?.copyWith(
                  color: tier.inkFaded,
                  fontSize: 8,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class _CardTier {
  const _CardTier({
    required this.top,
    required this.bottom,
    required this.border,
    required this.ink,
    required this.inkFaded,
  });

  final Color top;
  final Color bottom;
  final Color border;
  final Color ink;
  final Color inkFaded;

  static _CardTier of(int rating, AppSemanticColors colors) {
    final accent = switch (rating) {
      >= 75 => colors.warning,
      >= 65 => colors.info,
      _ => colors.textTertiary,
    };
    return _CardTier(
      top: Color.alphaBlend(
        accent.withValues(alpha: 0.22),
        colors.surfaceElevated,
      ),
      bottom: Color.alphaBlend(
        accent.withValues(alpha: 0.06),
        colors.surfaceElevated,
      ),
      border: Color.alphaBlend(
        accent.withValues(alpha: 0.35),
        colors.borderSubtle,
      ),
      ink: colors.textPrimary,
      inkFaded: colors.textSecondary,
    );
  }
}
