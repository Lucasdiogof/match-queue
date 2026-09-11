import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/player_card_face.dart';
import 'package:flutter/material.dart';

/// Detalhe completo de uma carta -- só mostra os campos que EXISTEM hoje no
/// schema (item 27): nada aqui inventa um valor ausente, o campo simplesmente
/// some da lista quando é `null`. Funciona sem quebrar mesmo para as cartas
/// `LOCAL` de dev, que não preenchem boa parte destes campos.
/// "Outras versões" (item 27 da Etapa 13): preparado, não ligado -- ver
/// comentário na seção correspondente abaixo. Vira `true` quando existir uma
/// consulta real por `fc_player_id`.
const bool _kShowOtherPlayerVersions = false;

Future<void> showPlayerCardDetailSheet({
  required BuildContext context,
  required PlayerCard card,
}) => showAppBottomSheet<void>(
  context: context,
  builder: (sheetContext) => _PlayerCardDetailBody(card: card),
);

class _PlayerCardDetailBody extends StatelessWidget {
  const _PlayerCardDetailBody({required this.card});

  final PlayerCard card;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppBottomSheet(
      title: card.displayName,
      subtitle: <String?>[
        card.clubName,
        card.leagueName,
        card.nationName,
      ].whereType<String>().join(' · '),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Com arte, ela lidera e ocupa o topo inteiro -- o resto da folha
            // complementa. Sem arte, nada de moldura vazia: os dados sobem
            // direto, que e o unico conteudo que existe.
            if ((card.cardImageUrl ?? card.playerImageUrl)
                case final art?) ...<Widget>[
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: AspectRatio(
                    aspectRatio: 0.72,
                    child: Image.network(
                      art,
                      fit: BoxFit.contain,
                      // Mesma razao do grid: sem CORS no CDN, o caminho por
                      // bytes falha na Web e o <img> resolve -- entao vai
                      // direto nele, sem a tentativa condenada antes.
                      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                      loadingBuilder: (context, child, progress) =>
                          progress == null ? child : const AppLoading.inline(),
                      // O AspectRatio reserva a altura de qualquer jeito, entao
                      // encolher o filho so deixava um buraco. A ficha ocupa o
                      // mesmo espaco com o conteudo que existe.
                      errorBuilder: (context, error, stackTrace) =>
                          PlayerCardDataFace(card: card),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Row(
              children: <Widget>[
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: <Widget>[
                      AppBadge(
                        label:
                            '${l10n.squadCardDetailRatingLabel} ${card.rating}',
                      ),
                      AppBadge(
                        label:
                            '${l10n.squadCardDetailPositionLabel}: '
                            '${card.primaryPosition}',
                      ),
                      if (card.cardType != null)
                        AppBadge(label: card.cardType!),
                      if (card.rarity != null) AppBadge(label: card.rarity!),
                    ],
                  ),
                ),
              ],
            ),
            if (card.alternativePositions.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              _Section(
                title: l10n.squadCardDetailAltPositionsLabel,
                child: Wrap(
                  spacing: AppSpacing.xs,
                  children: <Widget>[
                    for (final p in card.alternativePositions)
                      AppBadge(label: p),
                  ],
                ),
              ),
            ],
            if (!card.isGoalkeeper && _hasOutfieldStats(card)) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              _Section(
                title: l10n.squadCardDetailStatsTitle,
                child: _StatGrid(
                  entries: <MapEntry<String, int?>>[
                    MapEntry('PAC', card.pace),
                    MapEntry('SHO', card.shooting),
                    MapEntry('PAS', card.passing),
                    MapEntry('DRI', card.dribbling),
                    MapEntry('DEF', card.defending),
                    MapEntry('PHY', card.physical),
                  ],
                ),
              ),
            ],
            if (card.isGoalkeeper && _hasGkStats(card)) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              _Section(
                title: l10n.squadCardDetailGkStatsTitle,
                child: _StatGrid(
                  entries: <MapEntry<String, int?>>[
                    MapEntry('DIV', card.gkDiving),
                    MapEntry('HAN', card.gkHandling),
                    MapEntry('KIC', card.gkKicking),
                    MapEntry('REF', card.gkReflexes),
                    MapEntry('SPD', card.gkSpeed),
                    MapEntry('POS', card.gkPositioning),
                  ],
                ),
              ),
            ],
            if (card.weakFoot != null ||
                card.skillMoves != null ||
                card.preferredFoot != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              _Section(
                title: '',
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    if (card.weakFoot != null)
                      AppBadge(
                        label:
                            '${l10n.squadCardDetailWeakFootLabel}: '
                            '${card.weakFoot}★',
                      ),
                    if (card.skillMoves != null)
                      AppBadge(
                        label:
                            '${l10n.squadCardDetailSkillMovesLabel}: '
                            '${card.skillMoves}★',
                      ),
                    if (card.preferredFoot != null)
                      AppBadge(
                        label:
                            '${l10n.squadCardDetailPreferredFootLabel}: '
                            '${card.preferredFoot == 'LEFT' ? l10n.squadCardDetailPreferredFootLeft : l10n.squadCardDetailPreferredFootRight}',
                      ),
                  ],
                ),
              ),
            ],
            // Plus primeiro: e o atributo mais raro e o que o usuario procura.
            // A distincao vem das DUAS COLUNAS do banco, que sao disjuntas --
            // nunca de heuristica sobre o nome.
            if (card.playstylesPlus.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              _Section(
                title: l10n.squadCardDetailPlaystylesPlusTitle,
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: <Widget>[
                    // Tres sinais, nao so a cor: icone, o '+' que ja vem no
                    // proprio valor, e a secao separada com titulo proprio.
                    // So a cor excluiria quem nao a distingue.
                    for (final p in card.playstylesPlus)
                      AppBadge(
                        label: p,
                        tone: AppBadgeTone.warning,
                        icon: Icons.auto_awesome,
                      ),
                  ],
                ),
              ),
            ],
            if (card.playstyles.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              _Section(
                title: l10n.squadCardDetailPlaystylesTitle,
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: <Widget>[
                    for (final p in card.playstyles) AppBadge(label: p),
                  ],
                ),
              ),
            ],
            if (card.playerRoles.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              _Section(
                title: l10n.squadCardDetailRolesTitle,
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: <Widget>[
                    for (final r in card.playerRoles) AppBadge(label: r),
                  ],
                ),
              ),
            ],
            // "Outras versões" (item 27): PlayerCard.player (FcPlayer) já
            // existe desde a Etapa 12, mas nenhuma consulta/listagem de
            // outras cartas do mesmo atleta foi implementada aqui -- é só a
            // preparação visual pedida, escondida até existir dado real
            // para mostrar (produção roda com catálogo vazio hoje).
            // TODO(etapa-futura): listar outras cartas de card.player!.id
            // via uma RPC nova (ex. search_fc_player_cards com filtro por
            // fc_player_id) quando o catálogo real tiver múltiplas versões
            // do mesmo jogador.
            if (_kShowOtherPlayerVersions && card.player != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              _Section(
                title: l10n.squadCardDetailOtherVersionsTitle,
                child: Text(
                  l10n.squadCardDetailOtherVersionsComingSoon,
                  style: context.textStyles.bodySmall,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  bool _hasOutfieldStats(PlayerCard card) =>
      card.pace != null ||
      card.shooting != null ||
      card.passing != null ||
      card.dribbling != null ||
      card.defending != null ||
      card.physical != null;

  bool _hasGkStats(PlayerCard card) =>
      card.gkDiving != null ||
      card.gkHandling != null ||
      card.gkKicking != null ||
      card.gkReflexes != null ||
      card.gkSpeed != null ||
      card.gkPositioning != null;
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      if (title.isNotEmpty) ...<Widget>[
        Text(title.toUpperCase(), style: context.textStyles.labelSmall),
        const SizedBox(height: AppSpacing.sm),
      ],
      child,
    ],
  );
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.entries});

  final List<MapEntry<String, int?>> entries;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.lg,
    runSpacing: AppSpacing.sm,
    children: <Widget>[
      for (final entry in entries)
        if (entry.value != null)
          SizedBox(
            width: 72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  entry.key,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: context.colors.textTertiary,
                  ),
                ),
                Text('${entry.value}', style: context.textStyles.titleMedium),
              ],
            ),
          ),
    ],
  );
}
