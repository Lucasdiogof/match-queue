import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_squad.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/formation.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/squad_player_card.dart';
import 'package:flutter/material.dart';

/// Campo desenhado, nunca uma imagem com posições embutidas (item 24): as
/// linhas são pintadas pelo [_FieldPainter] e os slots ficam por cima,
/// posicionados pelas coordenadas normalizadas da formação. Trocar de
/// formação é só mudar a lista de slots.
class SquadField extends StatelessWidget {
  const SquadField({
    required this.squad,
    required this.onSlotTap,
    required this.onSlotLongPress,
    this.pendingSlotCode,
    this.savingSlotCode,
    super.key,
  });

  final FcSquadDetail squad;
  final void Function(FormationSlot slot) onSlotTap;
  final void Function(FormationSlot slot) onSlotLongPress;
  final String? pendingSlotCode;
  final String? savingSlotCode;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Proporção de campo. Um pouco mais alto que largo para os cards
        // caberem sem encostar uns nos outros.
        final height = width * 1.32;
        final cardWidth = (width / 5.4).clamp(48.0, 96.0);
        final cardHeight = cardWidth / SquadPlayerCard.aspectRatio;

        // Margem interna para o card não vazar do campo nas bordas.
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
                    color: colors.surface,
                    borderRadius: AppRadii.borderLg,
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: CustomPaint(
                    painter: _FieldPainter(
                      line: colors.borderStrong.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ),
              for (final slot in squad.formation.slots)
                Positioned(
                  // y do domínio cresce em direção ao gol adversário; a tela
                  // cresce para baixo. Inverter aqui é o que põe o goleiro
                  // embaixo e o ataque em cima (item 25).
                  left: insetX + slot.x * usableW - cardWidth / 2,
                  top: insetY + (1 - slot.y) * usableH - cardHeight / 2,
                  child: SquadPlayerCard(
                    positionCode: slot.positionCode,
                    width: cardWidth,
                    card: squad.cardAt(SquadSlotType.starting, slot.slotCode),
                    state: pendingSlotCode == slot.slotCode
                        ? SquadPlayerCardState.selected
                        : squad.cardAt(SquadSlotType.starting, slot.slotCode) ==
                              null
                        ? SquadPlayerCardState.empty
                        : SquadPlayerCardState.filled,
                    isSaving: savingSlotCode == slot.slotCode,
                    onTap: () => onSlotTap(slot),
                    onLongPress: () => onSlotLongPress(slot),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Linhas do campo. Minimalista de propósito: só o que dá leitura de campo
/// (meio, círculo, áreas, pequenas áreas) usando a cor de borda do tema, para
/// funcionar em claro e escuro sem nenhum verde fixo.
class _FieldPainter extends CustomPainter {
  const _FieldPainter({required this.line});

  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const pad = 10.0;
    final rect = Rect.fromLTWH(
      pad,
      pad,
      size.width - pad * 2,
      size.height - pad * 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      paint,
    );

    // Meio de campo
    canvas.drawLine(
      Offset(rect.left, rect.center.dy),
      Offset(rect.right, rect.center.dy),
      paint,
    );
    canvas.drawCircle(rect.center, rect.width * 0.14, paint);
    canvas.drawCircle(
      rect.center,
      2,
      Paint()
        ..color = line
        ..style = PaintingStyle.fill,
    );

    void box(double heightFactor, double widthFactor, {required bool bottom}) {
      final w = rect.width * widthFactor;
      final h = rect.height * heightFactor;
      canvas.drawRect(
        Rect.fromLTWH(
          rect.center.dx - w / 2,
          bottom ? rect.bottom - h : rect.top,
          w,
          h,
        ),
        paint,
      );
    }

    box(0.14, 0.58, bottom: true);
    box(0.14, 0.58, bottom: false);
    box(0.06, 0.30, bottom: true);
    box(0.06, 0.30, bottom: false);
  }

  @override
  bool shouldRepaint(_FieldPainter oldDelegate) => oldDelegate.line != line;
}
