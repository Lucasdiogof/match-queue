import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_squad.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/formation.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/squad_drag_payload.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/squad_player_card.dart';
import 'package:flutter/material.dart';

/// Tamanho do card do campo, adaptado à formação ativa (gameplay flows
/// refresh, item 4). Antes era um `width/5.4` fixo, que ficava maior que o
/// espaçamento real entre slots em formações com linhas densas (ex.: 5
/// defensores em 5-2-1-2), causando overlap visual.
///
/// Agrupa os slots por linha (mesmo `y`, arredondado -- a formação vem de
/// dado semeado, não de input livre, então linhas realmente alinhadas
/// batem exatamente após arredondar), acha o menor espaçamento horizontal
/// real entre slots vizinhos de cada linha, e usa o menor valor entre todas
/// as linhas como teto -- todos os cards do campo continuam do mesmo
/// tamanho entre si (nunca variação caótica por posição), só o teto
/// respeita a formação mais apertada. Função livre (não método privado) só
/// para poder ser testada isoladamente sem montar widget -- e reusada
/// pelo cartao de compartilhamento, que precisa do MESMO tamanho de
/// carta para a imagem sair igual ao campo da tela.
double cardWidthForFormation(List<FormationSlot> slots, double width) {
  final byRow = <double, List<double>>{};
  for (final slot in slots) {
    final rowKey = (slot.y * 100).round() / 100;
    (byRow[rowKey] ??= <double>[]).add(slot.x);
  }

  var minGapFraction = double.infinity;
  for (final xs in byRow.values) {
    if (xs.length < 2) {
      continue;
    }
    final sorted = xs..sort();
    for (var i = 1; i < sorted.length; i++) {
      final gap = sorted[i] - sorted[i - 1];
      if (gap < minGapFraction) {
        minGapFraction = gap;
      }
    }
  }

  const minCardWidth = 48.0;
  const maxCardWidth = 96.0;
  final baseline = (width / 5.4).clamp(minCardWidth, maxCardWidth);
  if (minGapFraction.isInfinite) {
    return baseline;
  }
  // Espaçamento em pixels, com uma pequena folga (0.9x) para o card nunca
  // encostar no vizinho mesmo com arredondamento. Nunca menor que o mínimo
  // absoluto -- prefere manter os cards legíveis a eliminar 100% do overlap
  // numa formação extrema.
  final maxByDensity = (minGapFraction * width * 0.9).clamp(
    minCardWidth,
    maxCardWidth,
  );
  return baseline < maxByDensity ? baseline : maxByDensity;
}

/// Campo desenhado, nunca uma imagem com posições embutidas (item 24): as
/// linhas são pintadas pelo [_FieldPainter] e os slots ficam por cima,
/// posicionados pelas coordenadas normalizadas da formação. Trocar de
/// formação é só mudar a lista de slots.
class SquadField extends StatelessWidget {
  const SquadField({
    required this.formation,
    required this.starters,
    required this.onSlotTap,
    required this.onSlotLongPress,
    required this.onSlotDrop,
    super.key,
  });

  /// Recebe o RASCUNHO, nao o elenco persistido: o campo tem de desenhar o
  /// que a pessoa esta montando, nao o que esta gravado.
  final FormationDefinition formation;
  final Map<String, PlayerCard> starters;

  final void Function(FormationSlot slot) onSlotTap;
  final void Function(FormationSlot slot) onSlotLongPress;
  final void Function(FormationSlot slot, SquadDragPayload payload) onSlotDrop;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Proporção de campo. Um pouco mais alto que largo para os cards
        // caberem sem encostar uns nos outros.
        final height = width * 1.32;
        final cardWidth = cardWidthForFormation(formation.slots, width);
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
              for (final slot in formation.slots)
                Positioned(
                  // y do domínio cresce em direção ao gol adversário; a tela
                  // cresce para baixo. Inverter aqui é o que põe o goleiro
                  // embaixo e o ataque em cima (item 25).
                  left: insetX + slot.x * usableW - cardWidth / 2,
                  top: insetY + (1 - slot.y) * usableH - cardHeight / 2,
                  width: cardWidth,
                  height: cardHeight,
                  child: Builder(
                    builder: (context) {
                      final card = starters[slot.slotCode];
                      return DraggableSquadSlot(
                        type: SquadSlotType.starting,
                        slotCode: slot.slotCode,
                        positionCode: slot.positionCode,
                        width: cardWidth,
                        card: card,
                        // Fora de posicao deixou de ser representavel: o
                        // picker so oferece quem joga ali e o remapeamento
                        // nunca encaixa incompativel.
                        state: card == null
                            ? SquadPlayerCardState.empty
                            : SquadPlayerCardState.filled,
                        onTap: () => onSlotTap(slot),
                        onLongPress: () => onSlotLongPress(slot),
                        onAccept: (payload) => onSlotDrop(slot, payload),
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
