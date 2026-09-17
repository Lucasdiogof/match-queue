import 'dart:math' as math;

import 'package:fifa_queue/core/design_system/theme/theme_context_extensions.dart';
import 'package:flutter/material.dart';

/// Fundo texturizado das telas do shell. Deliberadamente barato: um
/// [CustomPainter] com halo radial, linhas diagonais e grão bem esparso,
/// sem [BackdropFilter]/blur (evita jank em listas longas), sem imagens e
/// sem animação (nada disso muda quadro a quadro). Cada motivo é discreto
/// de propósito -- textura de fundo, não desenho visível a olho nu.
class AppBackground extends StatelessWidget {
  const AppBackground({
    required this.child,
    this.dense = false,
    this.glow,
    this.glowAlignment = const Alignment(0.7, -0.96),
    super.key,
  });

  final Widget child;

  /// Telas de detalhe/formulario usam a variante mais discreta: so o halo,
  /// sem os motivos decorativos (diagonais, grao) -- a leitura ali e o
  /// conteudo, nao a ambientacao.
  final bool dense;

  /// Tinge o halo. Nulo mantem o halo neutro, que e o padrao -- so a tela em
  /// que a cor significa alguma coisa deve pedir tinta.
  final Color? glow;

  /// Onde o halo nasce, em coordenadas de [Alignment]. O Jogar joga o halo
  /// para o meio da tela, atras da area de busca, em vez do canto.
  final Alignment glowAlignment;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.background),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _PitchTexturePainter(
                    accent: colors.textPrimary,
                    glow: glow,
                    glowAlignment: glowAlignment,
                    isDark: context.isDarkMode,
                    dense: dense,
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _PitchTexturePainter extends CustomPainter {
  const _PitchTexturePainter({
    required this.accent,
    required this.glow,
    required this.glowAlignment,
    required this.isDark,
    required this.dense,
  });

  final Color accent;
  final Color? glow;
  final Alignment glowAlignment;
  final bool isDark;
  final bool dense;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGlow(canvas, size);

    if (dense) {
      return;
    }

    _paintDiagonals(canvas, size);
    _paintGrain(canvas, size);
  }

  void _paintGlow(Canvas canvas, Size size) {
    final tint = glow ?? accent;
    // Halo tingido pode ser um pouco mais forte que o neutro e ainda ficar
    // discreto: cor saturada some antes de lavar a tela, branco nao.
    final base = glow == null
        ? (isDark ? 0.06 : 0.035)
        : (isDark ? 0.13 : 0.07);
    final glowOpacity = dense ? 0.02 : base;
    final glowCenter = glowAlignment.alongSize(size);
    final glowRadius = size.width * 0.9;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          tint.withValues(alpha: glowOpacity),
          tint.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: glowCenter, radius: glowRadius));
    canvas.drawRect(Offset.zero & size, glowPaint);
  }

  /// As diagonais esvaem no primeiro terco da tela: textura deve ser lida no
  /// topo e esquecida depois, nao virar papel de parede atras das listas.
  void _paintDiagonals(Canvas canvas, Size size) {
    final lineOpacity = isDark ? 0.045 : 0.03;
    final fade = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          accent.withValues(alpha: lineOpacity),
          accent.withValues(alpha: 0),
        ],
      ).createShader(Offset.zero & Size(size.width, size.height * 0.34))
      ..strokeWidth = 1;
    // Espacamento maior deixa a trama mais calma que a anterior de 42px.
    const spacing = 64.0;
    canvas.save();
    canvas.clipRect(Offset.zero & Size(size.width, size.height * 0.34));
    for (double x = -size.height; x < size.width + size.height; x += spacing) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), fade);
    }
    canvas.restore();
  }

  /// Grao bem esparso, confinado as bordas superior/inferior -- a faixa
  /// central (onde cards e listas moram) fica limpa. Posicoes vem de um
  /// hash deterministico (seno com passo irracional), nao de [math.Random]:
  /// mesmo tamanho de tela sempre produz o mesmo grao, entao nao "pisca"
  /// entre rebuilds.
  void _paintGrain(Canvas canvas, Size size) {
    final opacity = isDark ? 0.025 : 0.015;
    final paint = Paint()..color = accent.withValues(alpha: opacity);
    const count = 22;
    for (var i = 0; i < count; i++) {
      final fx = _hash(i * 12.9898);
      // Metade do grao na faixa de cima, metade embaixo -- nunca no meio.
      final band = i.isEven
          ? _hash(i * 78.233) * 0.14
          : 1 - _hash(i * 39.11) * 0.12;
      final radius = 0.5 + _hash(i * 4.71) * 0.6;
      canvas.drawCircle(
        Offset(fx * size.width, band * size.height),
        radius,
        paint,
      );
    }
  }

  static double _hash(double seed) {
    final v = math.sin(seed) * 43758.5453;
    return v - v.floorToDouble();
  }

  @override
  bool shouldRepaint(covariant _PitchTexturePainter oldDelegate) =>
      oldDelegate.accent != accent ||
      oldDelegate.glow != glow ||
      oldDelegate.glowAlignment != glowAlignment ||
      oldDelegate.isDark != isDark ||
      oldDelegate.dense != dense;
}
