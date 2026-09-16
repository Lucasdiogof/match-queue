import 'dart:async';
import 'dart:math' as math;

import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Redesenha a cada segundo so pra atualizar o texto/anel na tela -- quem
/// decide quando o tempo realmente acabou e sempre o servidor (lazy
/// expiration + cron), nunca este widget. O restante e calculado a cada
/// tick contra estimatedServerNow(), que ja embute a correcao de clock
/// drift calculada pelo MatchmakingCubit a cada snapshot novo.
///
/// A parte visual ("Chronos Engine": aneis girando + particulas + glow
/// central) e so decoracao por cima dessa mesma logica -- nunca calcula
/// segundos, nunca decide quando notificar zero. Ver [_ChronosPainter] pra
/// onde a animacao de verdade acontece.
class MatchmakingTimerRing extends StatefulWidget {
  const MatchmakingTimerRing({
    required this.startedAt,
    required this.expiresAt,
    required this.estimatedServerNow,
    this.onReachedZero,
    this.size = 168,
    super.key,
  });

  final DateTime startedAt;
  final DateTime expiresAt;
  final DateTime Function() estimatedServerNow;

  /// Disparado uma unica vez por sessao quando o contador chega a zero na
  /// tela. Serve so pra pedir uma releitura antes do cron/evento chegar --
  /// quem marca a sessao como expirada continua sendo o servidor.
  final VoidCallback? onReachedZero;

  final double size;

  @override
  State<MatchmakingTimerRing> createState() => _MatchmakingTimerRingState();
}

class _MatchmakingTimerRingState extends State<MatchmakingTimerRing>
    with SingleTickerProviderStateMixin {
  Timer? _ticker;
  bool _notifiedZero = false;

  // --- Efeito visual (Chronos Engine) -----------------------------------
  //
  // Nunca e a fonte de verdade do countdown -- essa continua sendo soh
  // _ticker + estimatedServerNow(), como sempre foi. Um unico
  // AnimationController faz dois papeis ao mesmo tempo, de proposito (menos
  // um Ticker rodando):
  //   1. fornece o valor 0->1->0 (2.1s) usado pra "respiracao" do glow
  //      central;
  //   2. cada frame que ele anima ja notifica o CustomPainter pra repintar
  //      (via `repaint:`), entao os aneis/particulas -- cujos angulos vem
  //      de _elapsed, um Stopwatch independente -- ganham o mesmo
  //      "carona" de 60fps sem precisar de um segundo controller so pra
  //      isso.
  //
  // _elapsed (nao o .value do controller) e quem da a base de tempo pras
  // rotacoes: um AnimationController comum "enrola" de volta pra 0 a cada
  // repeticao, o que criaria um salto visivel na junta do loop assim que
  // os 3 aneis (periodos de 7s/11s/16s) descasassem da duracao do
  // controller. Stopwatch e monotonico e nunca enrola.
  late final AnimationController _pulseController;
  final Stopwatch _elapsed = Stopwatch();
  late final List<_ChronosParticle> _particles;
  bool? _reducedMotion;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });

    _particles = _ChronosParticle.generate();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // "Reduced motion" do sistema: para tudo (o CustomPainter para de ser
    // notificado e fica parado no ultimo frame), sem nunca afetar o
    // countdown em si. Checado aqui (nao no initState, onde o MediaQuery
    // ainda nao esta disponivel) e so reage quando o valor muda de fato,
    // pra nao reiniciar a animacao a cada rebuild.
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced == _reducedMotion) {
      return;
    }
    _reducedMotion = reduced;
    if (reduced) {
      _elapsed.stop();
      _pulseController.stop();
    } else {
      _elapsed.start();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MatchmakingTimerRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) {
      _notifiedZero = false;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _maybeNotifyZero(Duration remaining) {
    if (_notifiedZero || remaining > Duration.zero) {
      return;
    }
    _notifiedZero = true;
    final callback = widget.onReachedZero;
    if (callback == null) {
      return;
    }
    // Fora do build: chamar direto aqui emitiria estado durante a fase de
    // construcao do frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        callback();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rawRemaining = widget.expiresAt.difference(
      widget.estimatedServerNow(),
    );
    final remaining = rawRemaining.isNegative ? Duration.zero : rawRemaining;
    _maybeNotifyZero(remaining);
    final seconds = remaining.inSeconds;
    // Mesmo limiar de urgencia de antes (10s/30s) -- so o tom "normal"
    // trocou de textPrimary pro dourado competitivo do tema, pra combinar
    // com o glow/aneis novos em vez de destoar deles.
    final numberColor = seconds <= 10
        ? colors.danger
        : seconds <= 30
        ? colors.warning
        : colors.competitive;

    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _ChronosPainter(
                elapsed: _elapsed,
                pulse: _pulseController,
                particles: _particles,
                baseColor: colors.competitive,
                brightColor: AppColors.goldBright,
                repaint: _pulseController,
              ),
            ),
            Text(
              _format(seconds),
              style: AppTypography.timerDisplay(numberColor),
            ),
          ],
        ),
      ),
    );
  }

  String _format(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

enum _ChronosRing { outer, inner }

/// Parametros de UMA particula, sorteados uma unica vez (ver [generate]) e
/// depois so reproduzidos ao longo do tempo -- nunca recriados por frame.
/// Cada particula "vive" em loop: a cada `duration` segundos ela renasce no
/// mesmo angulo de spawn e refaz o mesmo trajeto tangencial.
class _ChronosParticle {
  const _ChronosParticle({
    required this.ring,
    required this.angle,
    required this.radiusJitter,
    required this.baseSize,
    required this.duration,
    required this.phase,
    required this.travel,
    required this.radialDrift,
    required this.direction,
    required this.glow,
  });

  final _ChronosRing ring;
  final double angle;
  final double radiusJitter;
  final double baseSize;
  final double duration;
  final double phase;
  final double travel;
  final double radialDrift;
  final double direction;
  final bool glow;

  static const List<double> _sizes = <double>[0.8, 1.2, 1.6, 2.2];

  static List<_ChronosParticle> generate() {
    final random = math.Random();
    final particles = <_ChronosParticle>[];

    void addBatch(
      _ChronosRing ring,
      int count,
      double direction,
      int glowCount,
    ) {
      for (var i = 0; i < count; i++) {
        particles.add(
          _ChronosParticle(
            ring: ring,
            angle: random.nextDouble() * 2 * math.pi,
            radiusJitter: (random.nextDouble() - 0.5) * 10,
            baseSize: _sizes[random.nextInt(_sizes.length)],
            duration: 1.6 + random.nextDouble() * 1.8,
            phase: random.nextDouble() * 4,
            travel: 14 + random.nextDouble() * 18,
            radialDrift: 4 + random.nextDouble() * 8,
            direction: direction,
            glow: i < glowCount,
          ),
        );
      }
    }

    // Sentido tangencial acompanha o sentido de rotacao do proprio anel
    // (outer gira horario, inner tracejado tambem) -- as particulas parecem
    // ser arremessadas pelo giro, nao flutuando por conta propria.
    addBatch(_ChronosRing.outer, 17, 1, 3);
    addBatch(_ChronosRing.inner, 11, 1, 2);
    return particles;
  }
}

/// Todo o "Chronos Engine": 3 aneis com rotacoes independentes, glow radial
/// central com respiracao discreta, e particulas com trajetoria tangencial.
/// Nunca calcula nada de countdown -- so recebe `elapsed`/`pulse` como
/// entrada e desenha.
///
/// Repinta via `repaint:` (ligado ao AnimationController de pulso do
/// widget pai), nunca via setState -- o Stack/Text acima so reconstroi uma
/// vez por segundo (tick do countdown), independente da taxa de quadros
/// desta animacao.
class _ChronosPainter extends CustomPainter {
  _ChronosPainter({
    required this.elapsed,
    required this.pulse,
    required this.particles,
    required this.baseColor,
    required this.brightColor,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final Stopwatch elapsed;
  final AnimationController pulse;
  final List<_ChronosParticle> particles;
  final Color baseColor;
  final Color brightColor;

  static const double _outerFraction = 0.40;
  static const double _middleFraction = 0.30;
  static const double _innerFraction = 0.245;

  // Periodos e sentidos diferentes de proposito -- se os 3 girassem juntos
  // o efeito leria como "um unico elemento girando", nao 3 camadas
  // independentes.
  static const double _outerPeriodSeconds = 16;
  static const double _middlePeriodSeconds = 11;
  static const double _innerPeriodSeconds = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final shortestSide = size.shortestSide;
    final outerRadius = shortestSide * _outerFraction;
    final middleRadius = shortestSide * _middleFraction;
    final innerRadius = shortestSide * _innerFraction;
    final elapsedSeconds = elapsed.elapsedMicroseconds / 1e6;

    final outerAngle = _angleFor(elapsedSeconds, _outerPeriodSeconds, true);
    final middleAngle = _angleFor(elapsedSeconds, _middlePeriodSeconds, false);
    final innerAngle = _angleFor(elapsedSeconds, _innerPeriodSeconds, true);

    _paintCoreGlow(canvas, center, innerRadius);
    _paintParticles(canvas, center, outerRadius, innerRadius, elapsedSeconds);
    _paintOuterRing(canvas, center, outerRadius, outerAngle);
    _paintMiddleRing(canvas, center, middleRadius, middleAngle);
    _paintInnerRing(canvas, center, innerRadius, innerAngle);
  }

  double _angleFor(double elapsedSeconds, double periodSeconds, bool cw) {
    final t = (elapsedSeconds / periodSeconds) % 1.0;
    final angle = t * 2 * math.pi;
    return cw ? angle : -angle;
  }

  void _paintCoreGlow(Canvas canvas, Offset center, double innerRadius) {
    final glowRadius = innerRadius * 0.95;
    // Respiracao bem discreta: 0.28 a 0.42 de intensidade, nunca um circulo
    // solido -- centro (stop 0) e borda (stop 1) ficam transparentes, so o
    // meio (stop 0.55) concentra o dourado.
    final intensity = 0.28 + pulse.value * 0.14;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          baseColor.withValues(alpha: 0),
          brightColor.withValues(alpha: intensity),
          baseColor.withValues(alpha: 0),
        ],
        stops: const <double>[0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(center, glowRadius, paint);
  }

  void _paintOuterRing(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
  ) {
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Unico glow borrado entre os 3 aneis (custo de GPU) -- "MUITO
    // discreto", so no anel externo, que e o mais proeminente.
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = baseColor.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, radius, glowPaint);

    // SweepGradient em vez de cor solida: um circulo uniforme girando seria
    // visualmente identico a um parado. O "ponto brilhante" viajando pela
    // circunferencia e o que torna a rotacao perceptivel.
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..shader = SweepGradient(
        colors: <Color>[
          baseColor.withValues(alpha: 0.10),
          baseColor.withValues(alpha: 0.60),
          brightColor.withValues(alpha: 0.85),
          baseColor.withValues(alpha: 0.60),
          baseColor.withValues(alpha: 0.10),
        ],
        stops: const <double>[0.0, 0.18, 0.5, 0.82, 1.0],
        transform: GradientRotation(angle),
      ).createShader(rect);
    canvas.drawCircle(center, radius, ringPaint);
  }

  void _paintMiddleRing(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
  ) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..shader = SweepGradient(
        colors: <Color>[
          baseColor.withValues(alpha: 0.06),
          baseColor.withValues(alpha: 0.42),
          brightColor.withValues(alpha: 0.55),
          baseColor.withValues(alpha: 0.42),
          baseColor.withValues(alpha: 0.06),
        ],
        stops: const <double>[0.0, 0.2, 0.5, 0.8, 1.0],
        transform: GradientRotation(angle),
      ).createShader(rect);
    canvas.drawCircle(center, radius, ringPaint);
  }

  void _paintInnerRing(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..color = baseColor.withValues(alpha: 0.65);
    _drawDashedCircle(
      canvas,
      center,
      radius,
      paint,
      dashLength: 7,
      gapLength: 5,
      rotation: angle,
    );
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint, {
    required double dashLength,
    required double gapLength,
    required double rotation,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final dashAngle = dashLength / radius;
    final gapAngle = gapLength / radius;
    final step = dashAngle + gapAngle;
    var start = rotation % (2 * math.pi);
    var swept = 0.0;
    while (swept < 2 * math.pi) {
      final remaining = 2 * math.pi - swept;
      canvas.drawArc(rect, start, math.min(dashAngle, remaining), false, paint);
      start += step;
      swept += step;
    }
  }

  void _paintParticles(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double innerRadius,
    double elapsedSeconds,
  ) {
    final dot = Paint()..style = PaintingStyle.fill;
    final glowDot = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);

    for (final particle in particles) {
      final ringRadius = particle.ring == _ChronosRing.outer
          ? outerRadius
          : innerRadius;
      final spawnRadius = ringRadius + particle.radiusJitter;

      final t =
          ((elapsedSeconds + particle.phase) % particle.duration) /
          particle.duration;
      // Fade-in rapido (12% da vida) evita "pop" no nascimento; o resto da
      // vida e fade-out ate sumir.
      final opacity = t < 0.12 ? t / 0.12 : (1 - t) / 0.88;
      final scale = 0.6 + 0.4 * math.sin(math.pi * t);

      final radial = Offset(math.cos(particle.angle), math.sin(particle.angle));
      final tangent =
          Offset(-math.sin(particle.angle), math.cos(particle.angle)) *
          particle.direction;

      final travelled = particle.travel * t;
      final radialOffset = particle.radialDrift * t;

      final position =
          center +
          radial * spawnRadius +
          tangent * travelled +
          radial * radialOffset;

      final alpha = opacity.clamp(0.0, 1.0) * 0.85;
      final radius = particle.baseSize * scale;

      if (particle.glow) {
        glowDot.color = brightColor.withValues(alpha: alpha * 0.7);
        canvas.drawCircle(position, radius * 2.2, glowDot);
      }
      dot.color = (particle.glow ? brightColor : baseColor).withValues(
        alpha: alpha,
      );
      canvas.drawCircle(position, radius, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _ChronosPainter oldDelegate) =>
      oldDelegate.baseColor != baseColor ||
      oldDelegate.brightColor != brightColor ||
      !identical(oldDelegate.particles, particles);
}
