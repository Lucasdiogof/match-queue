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
    final art = card.cardImageUrl ?? card.playerImageUrl;

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 0.72,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            color: colors.surfaceElevated,
            border: Border.all(
              color: isSelected ? colors.textPrimary : colors.borderSubtle,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.md),
            // Com arte real a carta E a imagem: nada de moldura desenhada por
            // cima, porque a arte ja traz overall, posicao, clube e nacao.
            child: art == null
                ? PlayerCardDataFace(card: card, eligibility: eligibility)
                : _ArtCard(art: art, card: card, eligibility: eligibility),
          ),
        ),
      ),
    );
  }
}

class _ArtCard extends StatelessWidget {
  const _ArtCard({
    required this.art,
    required this.card,
    required this.eligibility,
  });

  final String art;
  final PlayerCard card;
  final int? eligibility;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: <Widget>[
      Image.network(
        art,
        fit: BoxFit.contain,
        // Na Web o CDN da arte permite hotlink por <img> mas nao devolve
        // Access-Control-Allow-Origin, e o caminho padrao do Flutter busca os
        // bytes por XHR -- que o navegador bloqueia.
        //
        // `prefer` e nao `fallback`: como o CORS aqui nunca vai passar, tentar
        // os bytes antes so gastaria uma requisicao condenada e sujaria o
        // console com um erro por carta. Vai direto ao <img>, que e o caminho
        // que de fato funciona. Fora da Web o parametro e ignorado.
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : const AppLoading.inline(),
        errorBuilder: (context, error, stackTrace) =>
            PlayerCardDataFace(card: card, eligibility: eligibility),
      ),
      if (eligibility != null)
        Positioned(
          top: AppSpacing.xs,
          right: AppSpacing.xs,
          child: _EligibilityDot(eligibility: eligibility!),
        ),
    ],
  );
}

/// Sem arte, a carta deixa de fingir ser um retrato e vira o que de fato e:
/// uma ficha. Um monograma gigante no meio so anunciava a imagem que falta --
/// aqui o espaco vai para o que existe de verdade.
///
/// Publica porque e o fallback em dois lugares: aqui e no detalhe, que antes
/// deixava um vazio de 260px quando a imagem falhava.
class PlayerCardDataFace extends StatelessWidget {
  const PlayerCardDataFace({required this.card, this.eligibility, super.key});

  final PlayerCard card;
  final int? eligibility;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = _tierAccent(card.rating, colors);
    final context_ = <String>[
      if (card.clubName != null) card.clubName!,
      if (card.nationName != null) card.nationName!,
    ];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${card.rating}',
                style: context.textStyles.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              // Flexible + elipse: posicao longa ou escala de fonte grande
              // encolhe aqui em vez de empurrar a Row para fora da carta.
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    card.primaryPosition,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.labelSmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (eligibility != null)
                _EligibilityDot(eligibility: eligibility!),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // Faixa fina por tier: o suficiente pra distinguir de relance, sem
          // o gradiente dourado que imitava a arte de outra marca.
          Container(width: 28, height: 2, color: accent),
          const Spacer(),
          Text(
            card.displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.titleSmall?.copyWith(height: 1.15),
          ),
          if (context_.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              context_.join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.labelSmall?.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _Attributes(card: card),
        ],
      ),
    );
  }
}

class _EligibilityDot extends StatelessWidget {
  const _EligibilityDot({required this.eligibility});

  final int eligibility;

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: switch (eligibility) {
        0 => context.colors.success,
        1 => context.colors.info,
        _ => context.colors.textTertiary,
      },
    ),
  );
}

Color _tierAccent(int rating, AppSemanticColors colors) => switch (rating) {
  >= 85 => colors.textPrimary,
  >= 75 => colors.textSecondary,
  _ => colors.borderStrong,
};

class _Attributes extends StatelessWidget {
  const _Attributes({required this.card});

  final PlayerCard card;

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
        _AttributeRow(entries: entries.sublist(0, 3)),
        const SizedBox(height: AppSpacing.xxs),
        _AttributeRow(entries: entries.sublist(3)),
      ],
    );
  }
}

class _AttributeRow extends StatelessWidget {
  const _AttributeRow({required this.entries});

  final List<(String, int?)> entries;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      for (final entry in entries)
        Expanded(
          // `overflow: clip` so corta a PINTURA: o Text continua informando a
          // largura inteira ao Row, que entao estoura por fracao de pixel
          // assim que valor + rotulo passam da coluna -- foi dai que veio o
          // "overflowed by 0.403 pixels".
          //
          // scaleDown resolve pela geometria: no tamanho normal nada muda, e
          // quando nao couber (3 digitos, escala de fonte do aparelho, tela
          // estreita) o par encolhe junto, mantendo alinhamento e leitura.
          // Nao e reduzir fonte a esmo -- e o unico caso do arquivo em que a
          // unidade e pequena e indivisivel.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  entry.$2 == null ? '-' : '${entry.$2}',
                  maxLines: 1,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  entry.$1,
                  maxLines: 1,
                  softWrap: false,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: context.colors.textTertiary,
                    fontSize: 8,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}
