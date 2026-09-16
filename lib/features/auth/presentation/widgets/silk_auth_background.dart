import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Fundo animado "silk" (tecido fluido, ondas organicas muito lentas) usado
/// SOMENTE na web, SOMENTE nas telas de login/cadastro -- ver uso em
/// [AuthFormScaffold]. No mobile essas telas continuam com a foto de
/// estadio de sempre; isso aqui e so a versao web daquele mesmo papel
/// (ambientacao atras do formulario, nunca competindo com ele).
///
/// Sem shaders/pacotes externos: cada "dobra" de tecido e uma faixa
/// horizontal com espessura constante cuja linha central oscila com duas
/// senoides de frequencia/fase diferentes (evita um movimento robotico de
/// onda unica), desenhada com blur pesado pra ficar macia. O tempo vem de um
/// [Stopwatch] em vez de um Tween 0->1 -- nunca da voltas, entao a animacao
/// nunca "corta" ou reinicia visivelmente.
class SilkAuthBackground extends StatefulWidget {
  const SilkAuthBackground({required this.child, super.key});

  final Widget child;

  @override
  State<SilkAuthBackground> createState() => _SilkAuthBackgroundState();
}

class _SilkAuthBackgroundState extends State<SilkAuthBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Stopwatch _elapsed = Stopwatch();
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery so pode ser lido depois que a arvore de InheritedWidget
    // esta montada -- initState() e cedo demais (ver erro do Flutter:
    // "dependOnInheritedWidgetOfExactType... called before initState()
    // completed"). didChangeDependencies() roda uma vez logo apos initState
    // (e de novo se o MediaQuery mudar), entao _started evita reiniciar o
    // controller a cada mudanca.
    if (!_started && !MediaQuery.disableAnimationsOf(context)) {
      _started = true;
      _elapsed.start();
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: <Widget>[
      const ColoredBox(color: _SilkPalette.background),
      RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _SilkPainter(
              elapsedSeconds: _elapsed.elapsedMilliseconds / 1000,
            ),
          ),
        ),
      ),
      // Vinheta invertida: mantem a coluna central (onde o formulario mora)
      // sempre a mais escura da tela, independente de como as ondas caem
      // naquele instante -- as laterais podem respirar mais brilho/movimento.
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.1,
            colors: <Color>[Colors.black54, Colors.transparent],
            stops: <double>[0, 1],
          ),
        ),
      ),
      widget.child,
    ],
  );
}

class _SilkPalette {
  const _SilkPalette._();

  static const Color background = Color(0xFF020605);
  static const Color deep = Color(0xFF03130E);
  static const Color green = Color(0xFF00A84F);
  static const Color bright = Color(0xFF00D47A);
}

class _SilkBand {
  const _SilkBand({
    required this.color,
    required this.alpha,
    required this.thicknessFactor,
    required this.centerFactor,
    required this.ampAFactor,
    required this.ampBFactor,
    required this.freqA,
    required this.freqB,
    required this.speedA,
    required this.speedB,
    required this.phase,
    required this.blurSigma,
  });

  final Color color;
  final double alpha;
  final double thicknessFactor;
  final double centerFactor;
  final double ampAFactor;
  final double ampBFactor;
  final double freqA;
  final double freqB;
  final double speedA;
  final double speedB;
  final double phase;
  final double blurSigma;
}

// Periodos bem longos e nao-multiplos entre si (60-140s) de proposito --
// "movimento MUITO lento, sem cortes perceptiveis" do pedido original. Cada
// faixa tem sua propria velocidade/fase pra nunca sincronizar visivelmente
// com as outras.
const List<_SilkBand> _bands = <_SilkBand>[
  _SilkBand(
    color: _SilkPalette.deep,
    alpha: 0.85,
    thicknessFactor: 0.55,
    centerFactor: 0.62,
    ampAFactor: 0.10,
    ampBFactor: 0.05,
    freqA: 1.1,
    freqB: 2.3,
    speedA: 2 * math.pi / 95,
    speedB: 2 * math.pi / 61,
    phase: 0.6,
    blurSigma: 70,
  ),
  _SilkBand(
    color: _SilkPalette.green,
    alpha: 0.14,
    thicknessFactor: 0.34,
    centerFactor: 0.34,
    ampAFactor: 0.08,
    ampBFactor: 0.04,
    freqA: 1.7,
    freqB: 0.9,
    speedA: 2 * math.pi / 78,
    speedB: 2 * math.pi / 132,
    phase: 2.1,
    blurSigma: 55,
  ),
  _SilkBand(
    color: _SilkPalette.bright,
    alpha: 0.10,
    thicknessFactor: 0.16,
    centerFactor: 0.78,
    ampAFactor: 0.07,
    ampBFactor: 0.03,
    freqA: 2.4,
    freqB: 1.3,
    speedA: 2 * math.pi / 68,
    speedB: 2 * math.pi / 110,
    phase: 4.4,
    blurSigma: 45,
  ),
  _SilkBand(
    color: _SilkPalette.bright,
    alpha: 0.06,
    thicknessFactor: 0.10,
    centerFactor: 0.16,
    ampAFactor: 0.05,
    ampBFactor: 0.025,
    freqA: 1.4,
    freqB: 2.6,
    speedA: 2 * math.pi / 140,
    speedB: 2 * math.pi / 89,
    phase: 1.2,
    blurSigma: 40,
  ),
];

class _SilkPainter extends CustomPainter {
  _SilkPainter({required this.elapsedSeconds});

  final double elapsedSeconds;

  static const int _segments = 32;

  @override
  void paint(Canvas canvas, Size size) {
    for (final band in _bands) {
      _paintBand(canvas, size, band);
    }
  }

  void _paintBand(Canvas canvas, Size size, _SilkBand band) {
    final centerY = size.height * band.centerFactor;
    final thickness = size.height * band.thicknessFactor;
    final ampA = size.height * band.ampAFactor;
    final ampB = size.height * band.ampBFactor;

    double waveY(double x) {
      final fx = x / size.width;
      final a = math.sin(
        fx * band.freqA * 2 * math.pi +
            elapsedSeconds * band.speedA +
            band.phase,
      );
      final b = math.sin(
        fx * band.freqB * 2 * math.pi -
            elapsedSeconds * band.speedB +
            band.phase * 1.7,
      );
      return centerY + a * ampA + b * ampB;
    }

    final top = Path()..moveTo(0, waveY(0) - thickness / 2);
    for (var i = 1; i <= _segments; i++) {
      final x = size.width * i / _segments;
      top.lineTo(x, waveY(x) - thickness / 2);
    }
    for (var i = _segments; i >= 0; i--) {
      final x = size.width * i / _segments;
      top.lineTo(x, waveY(x) + thickness / 2);
    }
    top.close();

    final paint = Paint()
      ..color = band.color.withValues(alpha: band.alpha)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, band.blurSigma);
    canvas.drawPath(top, paint);
  }

  @override
  bool shouldRepaint(covariant _SilkPainter oldDelegate) =>
      oldDelegate.elapsedSeconds != elapsedSeconds;
}
