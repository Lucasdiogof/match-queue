import 'package:fifa_queue/core/design_system/branding/brand_assets.dart';
import 'package:fifa_queue/core/design_system/theme/theme_context_extensions.dart';
import 'package:fifa_queue/core/design_system/tokens/app_durations.dart';
import 'package:fifa_queue/core/design_system/tokens/app_typography.dart';
import 'package:flutter/material.dart';

/// Wordmark "MATCH / QUEUE" desenhado em código -- substitui a arte cromada
/// (`assets/brand/wordmark.png`) nas telas de login e cadastro, que são onde
/// a marca aparece grande e sozinha. Não mexe em [BrandAssets.wordmark] nem
/// em [BrandWordmark]: splash, onboarding e o rail de navegação continuam
/// usando a arte de sempre -- só o par login/cadastro trocou.
///
/// Tipografia primeiro, efeito depois (95%/5%, de propósito): duas linhas
/// bem juntas em peso pesado, leve cisalhamento pro bloco inteiro, e só
/// acabamento por cima -- microprofundidade verde-escura atrás do texto, um
/// gradiente quase imperceptível no branco, e um único acento animado (três
/// pontinhos verdes, ver [_QueueDotsIndicator]) colado no fim de QUEUE,
/// lembrando fila/loading. Nada de recorte na letra, nada de neon, nada de
/// chrome. Cor vem 100% de [AppThemeX.colors]/[AppThemeX.isDarkMode], que
/// já reagem a `Theme.of(context).brightness` -- sem `isDark` manual em
/// lugar nenhum.
class MatchQueueWordmark extends StatefulWidget {
  const MatchQueueWordmark({this.height = 72, this.animate = true, super.key});

  final double height;

  /// Entrada curta (opacidade + leve translação/escala) na primeira
  /// montagem. Roda uma vez só, nunca repete -- ver [AppDurations.slow].
  final bool animate;

  @override
  State<MatchQueueWordmark> createState() => _MatchQueueWordmarkState();
}

class _MatchQueueWordmarkState extends State<MatchQueueWordmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppDurations.slow);
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery so pode ser lido depois que a arvore esta montada -- mesma
    // regra do SilkAuthBackground. _started evita reiniciar a entrada se
    // didChangeDependencies rodar de novo (ex.: mudanca de tema).
    if (!_started) {
      _started = true;
      if (widget.animate && !MediaQuery.disableAnimationsOf(context)) {
        _controller.forward();
      } else {
        _controller.value = 1;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: BrandAssets.productName,
    image: true,
    child: ExcludeSemantics(
      child: SizedBox(
        height: widget.height,
        child: FittedBox(
          fit: BoxFit.contain,
          child: AnimatedBuilder(
            animation: _curve,
            builder: (context, child) => Opacity(
              opacity: _curve.value,
              child: Transform.translate(
                offset: Offset(0, (1 - _curve.value) * 8),
                child: Transform.scale(
                  scale: 0.98 + _curve.value * 0.02,
                  child: child,
                ),
              ),
            ),
            child: const _WordmarkGlyph(),
          ),
        ),
      ),
    ),
  );
}

/// O desenho em si, num tamanho canônico -- o [FittedBox] do widget acima
/// escala isso pro `height` pedido preservando proporção, então não há
/// cálculo de responsividade aqui dentro: só o desenho, uma vez.
class _WordmarkGlyph extends StatelessWidget {
  const _WordmarkGlyph();

  static const double _fontSize = 40;
  static const double _lineHeight = 0.84;
  static const double _letterSpacing = -0.5;

  /// Radianos, pequeno de propósito -- dá a sensação de "inclinado pra
  /// frente" sem depender de itálico sintético, que varia de qualidade
  /// entre as fontes do fallback em cada plataforma. Aplicado ao BLOCO
  /// inteiro (texto + acento), nunca por letra.
  static const double _skew = -0.1;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDarkMode;
    final primary = colors.textPrimary;
    final accent = colors.accent;

    // Gradiente extremamente sutil: topo um tico mais claro que o corpo do
    // texto. É o suficiente pra tirar a sensação de flat total sem parecer
    // metálico -- a diferença entre as duas cores é pequena de propósito.
    //
    // Vai em TextStyle.foreground (não ShaderMask): ShaderMask recolore
    // TUDO que tem alpha por cima do texto, inclusive a sombra preta
    // abaixo -- ela viraria um halo esbranquiçado em vez de sombra. Como
    // paint de preenchimento, o shader some depois do lerp mesmo que
    // desça, e a sombra continua preta.
    final gradientShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        Color.lerp(primary, isDark ? Colors.white : colors.textSecondary, 0.3)!,
        primary,
      ],
      // Altura de uma linha só: as duas palavras usam o MESMO shader
      // (bounds fixos, não medidos), então o gradiente lê igual nas duas
      // em vez de reiniciar com intensidades diferentes por palavra.
    ).createShader(const Rect.fromLTWH(0, 0, 10, _fontSize));

    const baseStyle = TextStyle(
      fontSize: _fontSize,
      fontWeight: FontWeight.w900,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      height: _lineHeight,
      letterSpacing: _letterSpacing,
    );

    final mainStyle = baseStyle.copyWith(
      foreground: Paint()..shader = gradientShader,
      shadows: <Shadow>[
        Shadow(
          color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.10),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    );

    // Microprofundidade: uma cópia inteira do texto em verde bem escurecido,
    // 1.5px atrás -- não é sombra desenhada, é uma segunda camada de cor,
    // então só aparece como uma linha finíssima de verde nas bordas
    // inferior/direita das letras, nunca um efeito 3D.
    final depthStyle = baseStyle.copyWith(
      color: Color.lerp(accent, Colors.black, 0.5),
    );

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.skewX(_skew),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            left: 1.4,
            top: 1.6,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('MATCH', style: depthStyle),
                Text('QUEUE', style: depthStyle),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('MATCH', style: mainStyle),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text('QUEUE', style: mainStyle),
                  const SizedBox(width: 6),
                  // Único acento do wordmark: três pontinhos na vertical,
                  // acendendo em sequência -- fila/loading/progresso, sem
                  // desenhar uma seta ou uma barra literal.
                  _QueueDotsIndicator(color: accent),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Três pontinhos verdes na vertical, acendendo em sequência (fila
/// andando/loading), com uma pausa de ~1s com os três juntos antes de
/// reiniciar. Ciclo próprio e contínuo -- independente da entrada do
/// [MatchQueueWordmark] (que roda uma vez só), esse looping é intencional e
/// permanente, então tem seu próprio [AnimationController] em vez de dividir
/// o da entrada.
class _QueueDotsIndicator extends StatefulWidget {
  const _QueueDotsIndicator({required this.color});

  final Color color;

  @override
  State<_QueueDotsIndicator> createState() => _QueueDotsIndicatorState();
}

class _QueueDotsIndicatorState extends State<_QueueDotsIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _reducedMotion = false;
  bool _started = false;

  static const double _dotSize = 4.5;
  static const double _gap = 3.5;

  // Fracoes do ciclo de 2s (ver didChangeDependencies/duration): cada ponto
  // acende em 200ms, em sequencia (0-0.10, 0.10-0.20, 0.20-0.30 -- 600ms de
  // "subida" no total), os tres seguram ate 0.80 (mais 1000ms de hold,
  // exatamente o "~1 segundo" pedido), somem juntos ate 0.95 (300ms), e
  // ficam apagados ate o loop reiniciar em 1.0 -- essa pausa final e o que
  // faz o ciclo ler como um reinicio, nao um corte abrupto.
  static const double _holdEnd = 0.80;
  static const double _fadeOutEnd = 0.95;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _reducedMotion = MediaQuery.disableAnimationsOf(context);
      if (!_reducedMotion) {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _opacityAt(double t, double fadeInStart, double fadeInEnd) {
    if (t < fadeInStart) {
      return 0;
    }
    if (t < fadeInEnd) {
      return (t - fadeInStart) / (fadeInEnd - fadeInStart);
    }
    if (t < _holdEnd) {
      return 1;
    }
    if (t < _fadeOutEnd) {
      return 1 - (t - _holdEnd) / (_fadeOutEnd - _holdEnd);
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // Sem movimento: os tres pontos ficam visiveis e parados -- o detalhe
    // da marca continua ali, so sem animar.
    if (_reducedMotion) {
      return _dots(const <double>[1, 1, 1]);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return _dots(<double>[
          _opacityAt(t, 0, 0.10),
          _opacityAt(t, 0.10, 0.20),
          _opacityAt(t, 0.20, 0.30),
        ]);
      },
    );
  }

  Widget _dots(List<double> opacities) => Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      for (var i = 0; i < 3; i++) ...<Widget>[
        if (i != 0) const SizedBox(height: _gap),
        Opacity(
          opacity: opacities[i],
          child: Container(
            width: _dotSize,
            height: _dotSize,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ],
    ],
  );

  Color get color => widget.color;
}
