import 'package:flutter/material.dart';

/// Silhueta de "carta de jogo" -- retangulo arredondado com um bico
/// triangular no topo central -- usada pelo slot vazio da escalacao e pelo
/// card sem foto real (PlayerCardDataFace), pra ambos lerem como "a mesma
/// carta, so sem conteudo" em vez de caixas genericas.
///
/// Deliberadamente so a silhueta: sem gradiente dourado nem qualquer cor
/// fixa (isso fica por conta de quem usa, via `color`/tema), pra nao repetir
/// a identidade visual da EA -- ver doc comment de PlayerCardFace.
class CardShapeBorder extends OutlinedBorder {
  const CardShapeBorder({super.side = BorderSide.none});

  @override
  CardShapeBorder copyWith({BorderSide? side}) =>
      CardShapeBorder(side: side ?? this.side);

  Path _path(Rect rect) {
    final w = rect.width;
    final h = rect.height;
    final r = w * 0.10;
    final shoulderDrop = h * 0.035;
    final peakHalfWidth = w * 0.16;
    final midX = rect.left + w / 2;
    final shoulderY = rect.top + shoulderDrop;

    return Path()
      ..moveTo(rect.left, shoulderY + r)
      ..quadraticBezierTo(rect.left, shoulderY, rect.left + r, shoulderY)
      ..lineTo(midX - peakHalfWidth, shoulderY)
      ..lineTo(midX, rect.top)
      ..lineTo(midX + peakHalfWidth, shoulderY)
      ..lineTo(rect.right - r, shoulderY)
      ..quadraticBezierTo(rect.right, shoulderY, rect.right, shoulderY + r)
      ..lineTo(rect.right, rect.bottom - r)
      ..quadraticBezierTo(rect.right, rect.bottom, rect.right - r, rect.bottom)
      ..lineTo(rect.left + r, rect.bottom)
      ..quadraticBezierTo(rect.left, rect.bottom, rect.left, rect.bottom - r)
      ..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect.deflate(side.width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) {
      return;
    }
    canvas.drawPath(_path(rect.deflate(side.width / 2)), side.toPaint());
  }

  @override
  ShapeBorder scale(double t) => CardShapeBorder(side: side.scale(t));
}
