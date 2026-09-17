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
/// Não é mais uma distância única (hipotenusa) entre pares de slot: o card
/// é bem mais alto que largo ([SquadPlayerCard.aspectRatio] = 0.74), então
/// dois slots vizinhos na VERTICAL precisam de bem mais vão do que a mesma
/// distância normalizada entre vizinhos na HORIZONTAL -- tratar os dois
/// eixos como uma hipotenusa só subestimava o vão vertical necessário e
/// deixava cards de linhas próximas (ex. CDM sobre CAM) se tocando na
/// prática, mesmo com folga "matematicamente" suficiente.
///
/// Em vez disso, para cada par de slots calcula a maior largura de card que
/// caberia respeitando CADA eixo separadamente (a largura cabe se o vão
/// horizontal for >= largura, OU o vão vertical for >= altura = largura /
/// aspectRatio -- só um dos dois precisa se sustentar pra não sobrepor) e
/// usa o menor valor entre todos os pares como teto -- todos os cards do
/// campo continuam do mesmo tamanho entre si, só o teto respeita o par mais
/// apertado. Função livre (não método privado) só para poder ser testada
/// isoladamente sem montar widget -- e reusada pelo cartão de
/// compartilhamento, que precisa do MESMO tamanho de carta para a imagem
/// sair igual ao campo da tela.
double cardWidthForFormation(List<FormationSlot> slots, double width) {
  final height = width * fieldHeightRatio;
  const aspectRatio = SquadPlayerCard.aspectRatio;
  // Só 82% do vão real vira largura de carta, deixando uma margem visível
  // entre vizinhos mesmo depois de arredondamento.
  const safety = 0.82;

  var maxByPairs = double.infinity;
  for (var i = 0; i < slots.length; i++) {
    for (var j = i + 1; j < slots.length; j++) {
      final dxPx = (slots[i].x - slots[j].x).abs() * width;
      final dyPx = (slots[i].y - slots[j].y).abs() * height;
      final widthFromHorizontalGap = dxPx * safety;
      // altura = largura / aspectRatio, entao o vao vertical sustenta uma
      // largura de ate dyPx * aspectRatio antes de as alturas se tocarem.
      final widthFromVerticalGap = dyPx * safety * aspectRatio;
      final pairMax = math.max(widthFromHorizontalGap, widthFromVerticalGap);
      if (pairMax < maxByPairs) {
        maxByPairs = pairMax;
      }
    }
  }

  const minCardWidth = 48.0;
  const maxCardWidth = 96.0;
  final baseline = (width / 5.4).clamp(minCardWidth, maxCardWidth);
  if (maxByPairs.isInfinite) {
    return baseline;
  }
  final densityCeiling = maxByPairs.clamp(minCardWidth, maxCardWidth);
  return baseline < densityCeiling ? baseline : densityCeiling;
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
    this.corner,
    super.key,
  });

  /// Recebe o RASCUNHO, nao o elenco persistido: o campo tem de desenhar o
  /// que a pessoa esta montando, nao o que esta gravado.
  final FormationDefinition formation;
  final Map<String, PlayerCard> starters;

  final void Function(FormationSlot slot) onSlotTap;
  final void Function(FormationSlot slot) onSlotLongPress;
  final void Function(FormationSlot slot, SquadDragPayload payload) onSlotDrop;

  /// Constrói o cardzinho sobreposto no canto inferior direito do campo
  /// (hoje, o técnico), recebendo o lado disponível em pixels -- fica aqui
  /// e não no chamador porque só este widget sabe o tamanho real do campo
  /// (calculado abaixo), e o corner deve escalar junto com ele em vez de
  /// ficar num tamanho fixo que sobra ou aperta conforme a tela.
  final Widget Function(double size)? corner;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;

        // Campo mais alto que largo (fieldHeightRatio), cabendo dentro do
        // espaço disponível sem distorcer a proporção. Quando a altura é
        // conhecida (ex.: dentro do Expanded do builder), o campo cresce
        // até preencher o que sobrar -- por largura OU por altura, o que
        // for mais restritivo primeiro. Quando a altura é livre (ex.: numa
        // tela que rola, como o perfil público), cai de volta no cálculo
        // só-por-largura de sempre.
        double width;
        double height;
        if (maxHeight.isFinite) {
          final heightByWidth = maxWidth * fieldHeightRatio;
          if (heightByWidth <= maxHeight) {
            width = maxWidth;
            height = heightByWidth;
          } else {
            height = maxHeight;
            width = maxHeight / fieldHeightRatio;
          }
        } else {
          width = maxWidth;
          height = maxWidth * fieldHeightRatio;
        }

        final cardWidth = cardWidthForFormation(formation.slots, width);
        final cardHeight = cardWidth / SquadPlayerCard.aspectRatio;

        // Safe area interna: nunca cola a borda do campo. A margem some da
        // metade do card (pra ele nao vazar) mais uma folga fixa de
        // respiro visivel.
        const safeMargin = 10.0;
        final insetX = cardWidth / 2 + safeMargin;
        final insetY = cardHeight / 2 + safeMargin;
        final usableW = math.max(0.0, width - insetX * 2);
        final usableH = math.max(0.0, height - insetY * 2);

        final cornerSize = (width * 0.2).clamp(64.0, 96.0);

        return Center(
          child: SizedBox(
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
                if (corner != null)
                  Positioned(right: 12, bottom: 12, child: corner!(cornerSize)),
              ],
            ),
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
