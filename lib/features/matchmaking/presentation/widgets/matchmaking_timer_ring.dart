import 'dart:async';
import 'dart:math' as math;

import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';
import 'package:flutter/material.dart';

/// Paletas fixas por modo, pedidas explicitamente com hex exatos -- nao os
/// tokens champions*/rivals* do design system (mais escuros/dessaturados,
/// pensados pra preencher um card inteiro, nao pra um anel/glow fino sobre
/// fundo variavel). Cada campo e um PAPEL (onde a cor entra), nao uma cor
/// crua, pra `_ChronosPainter` nunca precisar saber qual modo esta sendo
/// desenhado -- so le os papeis.
class _RingTheme {
  const _RingTheme({
    required this.numberColor,
    required this.textGlow,
    required this.coreDeep,
    required this.coreMid,
    required this.corePeak,
    required this.corePeakIntensityBase,
    required this.corePeakIntensityPulse,
    required this.coreHaloAccent,
    required this.coreHaloAccentIntensity,
    required this.outerShadow,
    required this.outerShadowAlpha,
    required this.outerLow,
    required this.outerBright,
    required this.middleLow,
    required this.middleMid,
    required this.middleAccent,
    required this.innerColor,
    required this.innerAlpha,
    required this.particleMain,
    required this.particleAccent,
    required this.particleAlphaScale,
    required this.particleSizeScale,
  });

  /// Numero central e o glow (Shadow) direto no texto.
  final Color numberColor;
  final Color textGlow;

  /// Nucleo escuro do glow central (camada 1 -- ver _paintCoreGlow).
  final Color coreDeep;
  final Color coreMid;

  /// Brilho dourado do glow central (camada 2) e sua respiracao.
  final Color corePeak;
  final double corePeakIntensityBase;
  final double corePeakIntensityPulse;

  /// Halo na borda do glow central antes de sumir pro transparente --
  /// vermelho quente em Champions, quase imperceptivel roxo/azul em Rivals.
  final Color coreHaloAccent;
  final double coreHaloAccentIntensity;

  /// Anel externo: sombra/glow discreto por baixo + gradiente de varredura.
  final Color outerShadow;
  final double outerShadowAlpha;
  final Color outerLow;
  final Color outerBright;

  /// Anel intermediario: gradiente de varredura proprio, menos chamativo.
  final Color middleLow;
  final Color middleMid;
  final Color middleAccent;

  /// Anel interno tracejado.
  final Color innerColor;
  final double innerAlpha;

  /// Particulas: cor principal (maioria) e cor de destaque (poucas).
  final Color particleMain;
  final Color particleAccent;
  final double particleAlphaScale;
  final double particleSizeScale;

  // -------------------------------------------------------------- Champions
  //
  // Vermelho profundo como base estrutural, dourado forte como destaque --
  // visual "premium, forte e competitivo" pedido explicitamente com hex.
  static const _RingTheme champions = _RingTheme(
    numberColor: Color(0xFFF6D36B),
    textGlow: Color(0xFFF6D36B),
    coreDeep: Color(0xFF2A0A0F),
    coreMid: Color(0xFF3A1016),
    corePeak: Color(0xFFE6BE52),
    corePeakIntensityBase: 0.55,
    corePeakIntensityPulse: 0.20,
    coreHaloAccent: Color(0xFFB10F2E),
    coreHaloAccentIntensity: 0.22,
    outerShadow: Color(0xFF4A1A1F),
    outerShadowAlpha: 0.14,
    outerLow: Color(0xFF5B0013),
    outerBright: Color(0xFFE6BE52),
    middleLow: Color(0xFF7A0018),
    middleMid: Color(0xFF98001F),
    middleAccent: Color(0xFFD4A63A),
    innerColor: Color(0xFFE6BE52),
    innerAlpha: 0.80,
    particleMain: Color(0xFFE6BE52),
    particleAccent: Color(
      0xFFC1722B,
    ), // lerp(redHot #B10F2E, goldDark #B8860B, .35)
    particleAlphaScale: 0.85,
    particleSizeScale: 1.0,
  );

  // ------------------------------------------------------------------ Rivals
  //
  // Preto/grafite como base, dourado fosco/refinado como destaque -- "menos
  // vibrante que o Champions, mais elegante", com um toque quase
  // imperceptivel de roxo/azul escuro so no halo do glow.
  static const _RingTheme rivals = _RingTheme(
    numberColor: Color(0xFFF0D77A),
    textGlow: Color(0xFFF0D77A),
    coreDeep: Color(0xFF0D0D0F),
    coreMid: Color(0xFF1A1A1F),
    corePeak: Color(0xFFDDBB57),
    corePeakIntensityBase: 0.38,
    corePeakIntensityPulse: 0.14,
    coreHaloAccent: Color(0xFF24132E),
    coreHaloAccentIntensity: 0.10,
    outerShadow: Color(0xFF3A3A44),
    outerShadowAlpha: 0.10,
    outerLow: Color(0xFF121214),
    outerBright: Color(0xFFDDBB57),
    middleLow: Color(0xFF232329),
    middleMid: Color(0xFF2A2A31),
    middleAccent: Color(0xFFC79A2B),
    innerColor: Color(0xFFF0D77A),
    innerAlpha: 0.85,
    particleMain: Color(0xFFDDBB57),
    particleAccent: Color(
      0xFF9A9199,
    ), // lerp(graphiteLightest #3A3A44, goldDark #A97A14, .4)
    particleAlphaScale: 0.55,
    particleSizeScale: 0.78,
  );

  static _RingTheme resolve(GameMode? mode) => switch (mode) {
    GameMode.weekendLeague => champions,
    GameMode.divisionRivals => rivals,
    null => champions,
  };
}

/// Redesenha a cada segundo so pra atualizar o texto/anel na tela -- quem
/// decide quando o tempo realmente acabou e sempre o servidor (lazy
/// expiration + cron), nunca este widget. O restante e calculado a cada
/// tick contra estimatedServerNow(), que ja embute a correcao de clock
/// drift calculada pelo MatchmakingCubit a cada snapshot novo.
///
/// A parte visual ("Chronos Engine": aneis girando + particulas + glow
/// central) e so decoracao por cima dessa mesma logica -- nunca calcula
/// segundos, nunca decide quando notificar zero. Ver [_ChronosPainter] pra
/// onde a animacao de verdade acontece, e [_RingTheme] pra paleta por modo.
class MatchmakingTimerRing extends StatefulWidget {
  const MatchmakingTimerRing({
    required this.startedAt,
    required this.expiresAt,
    required this.estimatedServerNow,
    this.onReachedZero,
    this.gameMode,
    this.size = 224,
    super.key,
  });

  final DateTime startedAt;
  final DateTime expiresAt;
  final DateTime Function() estimatedServerNow;

  /// Disparado uma unica vez por sessao quando o contador chega a zero na
  /// tela. Serve so pra pedir uma releitura antes do cron/evento chegar --
  /// quem marca a sessao como expirada continua sendo o servidor.
  final VoidCallback? onReachedZero;

  /// So troca a paleta do efeito visual (Champions = vermelho+dourado,
  /// Rivals = preto/grafite+dourado). Nulo cai em Champions. Nunca
  /// influencia o calculo do countdown.
  final GameMode? gameMode;

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
    final theme = _RingTheme.resolve(widget.gameMode);
    // Mesmo limiar de urgencia de antes (10s/30s) -- perto de acabar ainda
    // vira vermelho/amarelo de alerta do proprio tema, sinal de urgencia
    // nao deve depender da paleta decorativa do modo.
    final numberColor = seconds <= 10
        ? colors.danger
        : seconds <= 30
        ? colors.warning
        : theme.numberColor;

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
                theme: theme,
                repaint: _pulseController,
              ),
            ),
            Text(
              _format(seconds),
              // Glow suave direto no texto (Shadow com blur), por cima do
              // glow do canvas atras dele -- reforca o numero sem precisar
              // desenhar nada extra.
              style: AppTypography.timerDisplay(numberColor).copyWith(
                shadows: <Shadow>[
                  Shadow(
                    color: theme.textGlow.withValues(alpha: 0.55),
                    blurRadius: 10,
                  ),
                ],
              ),
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
/// Nunca calcula nada de countdown -- so recebe `elapsed`/`pulse`/`theme`
/// como entrada e desenha; nunca sabe qual GameMode esta ativo, so a
/// paleta ja resolvida.
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
    required this.theme,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final Stopwatch elapsed;
  final AnimationController pulse;
  final List<_ChronosParticle> particles;
  final _RingTheme theme;

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

    _paintCoreGlow(canvas, center, middleRadius);
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

  void _paintCoreGlow(Canvas canvas, Offset center, double middleRadius) {
    // "Bola" grande o bastante pra encaixar o numero BEM folgado dentro
    // dela -- estoura pra alem do anel intermediario de proposito (o anel
    // intermediario passa a orbitar por cima da propria bola, como no
    // gear-2 da referencia).
    final glowRadius = middleRadius * 1.38;

    // Camada 1: nucleo escuro quase solido (papel coreDeep/coreMid do
    // theme). E o que da contraste de verdade pro numero -- um gradiente
    // so dourado-transparente lia bem num fundo ja escuro, mas lavava
    // contra um card claro (tema light) ou contra o proprio dourado do
    // numero. Igual as faixas Champions/Rivals que ja existem no app
    // (sempre escuras, nunca variam com o tema): o numero sempre pousa
    // sobre um "palco" escuro proprio, nao sobre o que tiver por baixo.
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          theme.coreDeep.withValues(alpha: 0.94),
          theme.coreMid.withValues(alpha: 0.82),
          theme.coreDeep.withValues(alpha: 0),
        ],
        stops: const <double>[0.0, 0.62, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius));
    canvas.drawCircle(center, glowRadius, corePaint);

    // Camada 2: brilho por cima do nucleo, mais concentrado perto do
    // numero, com respiracao discreta e um halo (coreHaloAccent) na borda
    // em vez de sumir direto pro transparente -- dourado puro desbotando
    // pro nada lia "solar"; passar por um acento antes de sumir da a
    // sensacao "premium" pedida (vermelho quente em Champions, um toque
    // quase imperceptivel de roxo/azul escuro em Rivals).
    final intensity =
        theme.corePeakIntensityBase +
        pulse.value * theme.corePeakIntensityPulse;
    final glowInnerRadius = glowRadius * 0.82;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          theme.corePeak.withValues(alpha: intensity),
          theme.corePeak.withValues(alpha: intensity * 0.55),
          theme.coreHaloAccent.withValues(
            alpha: intensity * theme.coreHaloAccentIntensity,
          ),
          theme.coreHaloAccent.withValues(alpha: 0),
        ],
        stops: const <double>[0.0, 0.45, 0.78, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: glowInnerRadius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(center, glowInnerRadius, glowPaint);
  }

  void _paintOuterRing(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
  ) {
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Unico glow borrado entre os 3 aneis (custo de GPU) -- "MUITO
    // discreto", so no anel externo, que e o mais proeminente. Tom neutro
    // (nunca a cor de destaque) da a sensacao de profundidade/sombra de
    // emblema pedida, em vez de so mais um halo colorido.
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = theme.outerShadow.withValues(alpha: theme.outerShadowAlpha)
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
          theme.outerLow.withValues(alpha: 0.10),
          theme.outerLow.withValues(alpha: 0.60),
          theme.outerBright.withValues(alpha: 0.85),
          theme.outerLow.withValues(alpha: 0.60),
          theme.outerLow.withValues(alpha: 0.10),
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
    // Paleta propria (middleLow/middleMid/middleAccent), menos chamativa
    // que o anel externo -- diferencia as duas camadas em vez de repetir o
    // mesmo brilho.
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..shader = SweepGradient(
        colors: <Color>[
          theme.middleLow.withValues(alpha: 0.06),
          theme.middleMid.withValues(alpha: 0.45),
          theme.middleAccent.withValues(alpha: 0.50),
          theme.middleMid.withValues(alpha: 0.45),
          theme.middleLow.withValues(alpha: 0.06),
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
    // Sempre a cor de destaque do modo (nunca a base estrutural) -- e o
    // anel que precisa continuar bem visivel por cima do nucleo/glow, os
    // outros dois ja carregam a identidade estrutural.
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..color = theme.innerColor.withValues(alpha: theme.innerAlpha);
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
    // Maioria das particulas usa particleMain (dourado); so as poucas
    // marcadas `glow` (5 de 28, ver _ChronosParticle.generate) usam
    // particleAccent -- discreto, nunca parecendo fogos/confete.
    // particleAlphaScale/particleSizeScale deixam a paleta Rivals inteira
    // mais contida ("poucas, muito discretas, menores") sem tocar na
    // contagem/estrutura das particulas em si.
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
      final scale =
          (0.6 + 0.4 * math.sin(math.pi * t)) * theme.particleSizeScale;

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

      final alpha = opacity.clamp(0.0, 1.0) * theme.particleAlphaScale;
      final radius = particle.baseSize * scale;

      if (particle.glow) {
        glowDot.color = theme.particleAccent.withValues(alpha: alpha * 0.7);
        canvas.drawCircle(position, radius * 2.2, glowDot);
      }
      dot.color = (particle.glow ? theme.particleAccent : theme.particleMain)
          .withValues(alpha: alpha);
      canvas.drawCircle(position, radius, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _ChronosPainter oldDelegate) =>
      oldDelegate.theme != theme ||
      !identical(oldDelegate.particles, particles);
}
