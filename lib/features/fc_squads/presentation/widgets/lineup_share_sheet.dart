import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/platform/share_service.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/lineup_draft.dart';
import 'package:fifa_queue/features/fc_squads/presentation/cubit/squad_builder_cubit.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/player_card_face.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/squad_field.dart';
import 'package:fifa_queue/features/public_profile/presentation/widgets/share_capture.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Compartilhar o Elenco como imagem.
///
/// Compartilha o RASCUNHO -- o que esta na tela, salvo ou nao. E uma
/// montagem visual, nao uma publicacao, entao nao exige salvar antes e nao
/// persiste nada por ter sido compartilhada. Tambem nao passa por
/// Privacidade: exposicao do perfil mora em Perfil > Compartilhamento e e
/// outra decisao.
///
/// A folha mostra o cartao antes de compartilhar de proposito: as cartas sao
/// imagens remotas, e ter o cartao na tela e o que garante que elas ja
/// carregaram quando a captura acontece.
Future<void> showLineupShareSheet({
  required BuildContext context,
  required SquadBuilderState state,
}) {
  final draft = state.draft;
  if (draft == null) {
    return Future<void>.value();
  }
  return showAppBottomSheet<void>(
    context: context,
    builder: (sheetContext) => AppBottomSheet(
      title: sheetContext.l10n.squadShareAction,
      isChildScrollable: true,
      child: _LineupShareBody(
        draft: draft,
        chemistry: state.chemistry,
        accountName: state.baseline?.name ?? '',
      ),
    ),
  );
}

class _LineupShareBody extends StatefulWidget {
  const _LineupShareBody({
    required this.draft,
    required this.chemistry,
    required this.accountName,
  });

  final LineupDraft draft;
  final int? chemistry;
  final String accountName;

  @override
  State<_LineupShareBody> createState() => _LineupShareBodyState();
}

class _LineupShareBodyState extends State<_LineupShareBody> {
  final GlobalKey _boundary = GlobalKey();
  bool _isSharing = false;

  Future<void> _share() async {
    setState(() => _isSharing = true);
    try {
      final bytes = await ShareCapture.captureBoundary(_boundary);
      if (bytes == null || !mounted) {
        return;
      }
      await getIt<ShareService>().shareImage(
        bytes,
        fileName: 'elenco.png',
        text: widget.accountName,
      );
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListView(
      shrinkWrap: true,
      children: <Widget>[
        RepaintBoundary(
          key: _boundary,
          child: LineupShareCard(
            draft: widget.draft,
            chemistry: widget.chemistry,
            accountName: widget.accountName,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: l10n.squadShareAction,
          icon: Icons.ios_share,
          isLoading: _isSharing,
          onPressed: _isSharing ? null : _share,
        ),
      ],
    );
  }
}

/// O cartao que vira imagem. Nunca captura a tela: AppBar, navegacao e
/// botoes nao entram porque nao fazem parte disto.
///
/// Sempre escuro, nos dois temas -- e um objeto para mandar no chat, nao uma
/// tela do app.
class LineupShareCard extends StatelessWidget {
  const LineupShareCard({
    required this.draft,
    required this.chemistry,
    required this.accountName,
    super.key,
  });

  final LineupDraft draft;
  final int? chemistry;
  final String accountName;

  /// No Web, carregar a arte remota por `<img>` sem CORS CONTAMINA o canvas,
  /// e `toImage()` passa a falhar -- a captura sairia vazia. Em vez de um
  /// proxy improvisado ou de baixar a arte por um caminho que o CDN nao
  /// autoriza, o cartao usa a ficha propria no Web. Nativo continua com a
  /// arte oficial.
  bool get _useArtwork => !kIsWeb;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: AppGradients.darkBrandSurface,
      borderRadius: AppRadii.borderLg,
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  accountName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleMedium?.copyWith(
                    color: AppColors.darkTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _Stat(label: draft.formation.code, value: ''),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ShareField(draft: draft, useArtwork: _useArtwork),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: _Stat(
                  label: context.l10n.squadOverallLabel,
                  value: draft.overall?.toString() ?? '--',
                ),
              ),
              Expanded(
                child: _Stat(
                  label: context.l10n.squadChemistryLabel,
                  value: chemistry == null ? '--' : '$chemistry/33',
                ),
              ),
              Expanded(
                child: _Stat(
                  label: context.l10n.squadManagerLabel,
                  value: draft.manager?.name ?? '--',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'FIFA QUEUE',
            textAlign: TextAlign.center,
            style: context.textStyles.labelSmall?.copyWith(
              color: AppColors.darkTextTertiary,
              letterSpacing: 2.4,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ShareField extends StatelessWidget {
  const _ShareField({required this.draft, required this.useArtwork});

  final LineupDraft draft;
  final bool useArtwork;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = width * 1.32;
      final cardWidth = cardWidthForFormation(draft.formation.slots, width);
      final cardHeight = cardWidth / 0.72;
      final insetX = cardWidth / 2 + 4;
      final insetY = cardHeight / 2 + 4;
      final usableW = width - insetX * 2;
      final usableH = height - insetY * 2;

      return SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceGreen,
                  borderRadius: AppRadii.borderMd,
                  border: Border.all(
                    color: AppColors.fcGreen.withValues(alpha: 0.18),
                  ),
                ),
              ),
            ),
            for (final slot in draft.formation.slots)
              Positioned(
                left: insetX + slot.x * usableW - cardWidth / 2,
                top: insetY + (1 - slot.y) * usableH - cardHeight / 2,
                width: cardWidth,
                height: cardHeight,
                child: Builder(
                  builder: (context) {
                    final card = draft.starters[slot.slotCode];
                    if (card == null) {
                      return _EmptySlot(label: slot.positionCode);
                    }
                    // Sem arte disponivel, a ficha propria entra no lugar --
                    // a imagem nunca sai com um buraco branco.
                    return useArtwork
                        ? PlayerCardFace(card: card)
                        : ClipRRect(
                            borderRadius: AppRadii.borderSm,
                            child: ColoredBox(
                              color: AppColors.darkSurfaceElevated,
                              child: AspectRatio(
                                aspectRatio: 0.72,
                                child: PlayerCardDataFace(card: card),
                              ),
                            ),
                          );
                  },
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: AppRadii.borderSm,
      border: Border.all(
        color: AppColors.darkTextTertiary.withValues(alpha: 0.35),
      ),
    ),
    child: Center(
      child: Text(
        label,
        maxLines: 1,
        style: context.textStyles.labelSmall?.copyWith(
          color: AppColors.darkTextTertiary,
        ),
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textStyles.labelSmall?.copyWith(
          color: AppColors.darkTextTertiary,
          letterSpacing: 1.1,
        ),
      ),
      if (value.isNotEmpty)
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textStyles.titleSmall?.copyWith(
            color: AppColors.darkTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
    ],
  );
}
