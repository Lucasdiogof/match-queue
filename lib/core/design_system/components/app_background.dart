import 'package:fifa_queue/core/design_system/theme/theme_context_extensions.dart';
import 'package:flutter/material.dart';

/// Fundo texturizado das telas do shell. Deliberadamente barato: um
/// [CustomPainter] com halo radial + linhas diagonais finas, sem
/// [BackdropFilter]/blur (evita jank em listas longas) e sem imagens.
class AppBackground extends StatelessWidget {
  const AppBackground({
    required this.child,
    this.dense = false,
    this.glow,
    this.glowAlignment = const Alignment(0.7, -0.96),
    super.key,
  });

  final Widget child;

  /// Telas de detalhe/formulario usam a variante mais discreta.
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

    if (dense) {
      return;
    }

    // As diagonais agora esvaem no primeiro terco da tela. Antes cobriam a
    // altura inteira e competiam com o conteudo -- textura deve ser lida no
    // topo e esquecida depois, nao virar papel de parede atras das listas.
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

  @override
  bool shouldRepaint(covariant _PitchTexturePainter oldDelegate) =>
      oldDelegate.accent != accent ||
      oldDelegate.glow != glow ||
      oldDelegate.glowAlignment != glowAlignment ||
      oldDelegate.isDark != isDark ||
      oldDelegate.dense != dense;
}
