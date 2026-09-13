import 'dart:math' as math;

import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_squad.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/formation.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/squad_drag_payload.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/squad_player_card.dart';
import 'package:flutter/material.dart';

/// Campo mais alto que largo, pro card caber sem encostar no vizinho.
/// Compartilhada com [cardWidthForFormation] (escala do eixo Y) e com o
/// cartão de compartilhamento, que desenha o mesmo campo numa imagem.
const double fieldHeightRatio = 1.32;

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
  // Distância mínima entre QUALQUER par de slots, não só os da mesma linha:
  // uma coluna central (ex. CAM logo acima de dois CM) fica mais perto na
  // diagonal do que os dois CM ficam um do outro na horizontal, e olhar só
  // pra linha deixava esse caso passar batido -- overlap real visto num
  // 4-1-2-1-2 com CAM/CDM entre os CM.
  //
  // x e y são frações de dimensões DIFERENTES (largura vs altura do campo,
  // que é mais alto que largo -- fieldHeightRatio), então dy é escalado por
  // esse fator antes do hipotenusa: sem isso, a mesma fração em x e em y
  // representaria distâncias reais diferentes e o cálculo subestimaria o
  // quão perto duas linhas realmente ficam.
  var minGapFraction = double.infinity;
  for (var i = 0; i < slots.length; i++) {
    for (var j = i + 1; j < slots.length; j++) {
      final dx = slots[i].x - slots[j].x;
      final dy = (slots[i].y - slots[j].y) * fieldHeightRatio;
      final distance = _hypot(dx, dy);
      if (distance < minGapFraction) {
        minGapFraction = distance;
      }
    }
  }

  const minCardWidth = 48.0;
  const maxCardWidth = 96.0;
  final baseline = (width / 5.4).clamp(minCardWidth, maxCardWidth);
  if (minGapFraction.isInfinite) {
    return baseline;
  }
  // Espaçamento em pixels, com uma folga (0.82x) para sobrar uma zona de
  // segurança visivel entre cards vizinhos mesmo com arredondamento. Nunca
  // menor que o mínimo absoluto -- prefere manter os cards legíveis a
  // eliminar 100% do overlap numa formação extrema.
  final maxByDensity = (minGapFraction * width * 0.82).clamp(
    minCardWidth,
    maxCardWidth,
  );
  return baseline < maxByDensity ? baseline : maxByDensity;
}

double _hypot(double dx, double dy) => math.sqrt(dx * dx + dy * dy);

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Proporção de campo. Um pouco mais alto que largo para os cards
        // caberem sem encostar uns nos outros.
        final height = width * fieldHeightRatio;
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
              const Positioned.fill(
                // O campo e escuro nos DOIS temas. Ele nao e uma superficie
                // da tela, e o modulo onde a montagem acontece -- e um
                // gramado claro tiraria o contraste justamente das cartas
                // Gold, que sao o assunto.
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppGradients.darkBrandSurface,
                    borderRadius: AppRadii.borderLg,
                    border: Border.fromBorderSide(
                      BorderSide(color: Color(0x2939E27D)),
                    ),
                  ),
                  child: CustomPaint(
                    painter: _FieldPainter(line: Color(0x1F39E27D)),
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
                        onRemove: card == null
                            ? null
                            : () => onSlotLongPress(slot),
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
/// o campo ler como campo. Agora com o verde da marca, porque o campo e
/// escuro nos dois temas -- ver a decoracao acima.
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
