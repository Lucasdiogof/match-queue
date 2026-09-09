import 'package:fifa_queue/core/design_system/theme/theme_context_extensions.dart';
import 'package:flutter/material.dart';

/// Fundo texturizado reutilizavel para as telas principais do shell (Inicio,
/// Times, Controle, Historico). Deliberadamente barato: um unico
/// [CustomPainter] com gradiente radial + linhas diagonais finas, sem
/// [BackdropFilter]/blur (evita jank em listas longas) e sem imagens.
class AppBackground extends StatelessWidget {
  const AppBackground({required this.child, this.dense = false, super.key});

  final Widget child;

  /// Telas de detalhe/formulario usam a variante mais discreta.
  final bool dense;

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
                  accent: colors.success,
                  background: colors.background,
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
    required this.background,
    required this.isDark,
    required this.dense,
  });

  final Color accent;
  final Color background;
  final bool isDark;
  final bool dense;

  @override
  void paint(Canvas canvas, Size size) {
    final glowOpacity = dense ? 0.05 : (isDark ? 0.14 : 0.08);
    final glowCenter = Offset(size.width * 0.85, size.height * 0.02);
    final glowRadius = size.width * 0.9;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          accent.withValues(alpha: glowOpacity),
          accent.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: glowCenter, radius: glowRadius));
    canvas.drawRect(Offset.zero & size, glowPaint);

    if (dense) {
      return;
    }

    final lineOpacity = isDark ? 0.05 : 0.035;
    final linePaint = Paint()
      ..color = accent.withValues(alpha: lineOpacity)
      ..strokeWidth = 1;
    const spacing = 42.0;
    final start = -size.height;
    for (double x = start; x < size.width + size.height; x += spacing) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PitchTexturePainter oldDelegate) =>
      oldDelegate.accent != accent ||
      oldDelegate.background != background ||
      oldDelegate.isDark != isDark ||
      oldDelegate.dense != dense;
}
