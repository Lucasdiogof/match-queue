import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/features/auth/presentation/widgets/silk_auth_background.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class AuthFormScaffold extends StatelessWidget {
  const AuthFormScaffold({
    required this.title,
    required this.children,
    this.subtitle,
    this.footer,
    this.onBack,
    this.backTooltip,
    this.backgroundImage,
    this.showWordmark = true,
    this.wordmark,
    this.darkBackground = false,
    this.contentAlignment,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final String? subtitle;
  final Widget? footer;
  final VoidCallback? onBack;
  final String? backTooltip;

  /// Imagem de fundo em tela cheia (foto de estadio, so ambientacao). O
  /// recorte fica ancorado embaixo (ver build()) pra nunca depender de onde
  /// a logo apareceria no source -- a logo de verdade e sempre a
  /// [BrandWordmark] normal, nunca a arte.
  final String? backgroundImage;

  /// Sem uso pratico hoje (a logo nunca vem mais embutida na arte), mas
  /// mantido para telas que queiram esconder a wordmark por algum outro
  /// motivo futuro.
  final bool showWordmark;

  /// Sobrescreve o widget exibido quando [showWordmark] e true. Sem isso,
  /// cai no padrao (`BrandWordmark`, o PNG cromado). Uso pontual pra telas
  /// que querem outra variante da marca (ex.: texto ao vivo no cadastro).
  final Widget? wordmark;

  /// Forca o tema escuro no fundo liso (sem [backgroundImage]), pra telas
  /// como recuperar senha que nao tem foto mas precisam do mesmo pano de
  /// fundo escuro do login/cadastro.
  final bool darkBackground;

  /// Sobrescreve o alinhamento vertical do conteudo dentro do [Expanded].
  /// Sem isso, o padrao e centralizado (ou ancorado ao rodape quando ha
  /// [backgroundImage]).
  final Alignment? contentAlignment;

  Widget _buildForm(BuildContext context) => Column(
    children: <Widget>[
      if (onBack != null)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              0,
              0,
            ),
            child: AppIconButton(
              icon: Icons.arrow_back,
              tooltip: backTooltip ?? '',
              onPressed: onBack,
            ),
          ),
        ),
      Expanded(
        child: Align(
          alignment:
              contentAlignment ??
              (backgroundImage != null
                  ? const Alignment(0, 0.45)
                  : Alignment.center),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: AppContentContainer.form(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (showWordmark) ...<Widget>[
                    Center(child: wordmark ?? const BrandWordmark(height: 76)),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  Text(title, style: context.textStyles.headlineMedium),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.sm),
                    Text(subtitle!, style: context.textStyles.bodyMedium),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
      if (footer != null)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: AppContentContainer.form(child: footer!),
        ),
    ],
  );

  /// Na web, as telas com [backgroundImage] trocam a foto de estadio (arte
  /// pensada pra mobile) pelo fundo animado "silk" -- so o visual de fundo
  /// muda; formulario, logo, navegacao e autenticacao continuam exatamente
  /// os mesmos widgets de sempre (mesmo [_buildForm]). No app nativo
  /// (Android/iOS) [kIsWeb] e sempre false, entao esse caminho nunca roda
  /// la -- a foto de estadio continua sendo o fundo.
  Widget _webBackground(BuildContext context) => Scaffold(
    body: SilkAuthBackground(
      child: SafeArea(
        child: Theme(
          data: AppTheme.dark,
          child: Builder(builder: _buildForm),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (backgroundImage != null && kIsWeb) {
      return _webBackground(context);
    }
    return Scaffold(
      body: backgroundImage != null
          ? Stack(
              fit: StackFit.expand,
              children: <Widget>[
                // A arte e retrato (pensada pra mobile) e so entra como
                // ambientacao -- nunca carrega a logo (essa e sempre a
                // BrandWordmark normal acima do titulo, ver _buildForm). A
                // logo desenhada na propria arte fica na metade de cima: em
                // telas cuja proporcao e parecida com a da arte (a maioria
                // dos celulares) o BoxFit.cover sozinho mal recorta nada, e
                // ela reaparece duplicada. O scale ancorado embaixo forca um
                // recorte minimo (~metade de baixo da arte) sempre, em
                // qualquer proporcao de tela.
                Transform.scale(
                  scale: 1.9,
                  alignment: Alignment.bottomCenter,
                  child: Image.asset(
                    backgroundImage!,
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[Colors.transparent, Colors.black87],
                      stops: <double>[0.45, 1],
                    ),
                  ),
                ),
                // Builder gives the themed subtree its own BuildContext, so
                // context.textStyles below actually resolves against
                // AppTheme.dark instead of the ambient (light) theme baked in
                // by the outer build() call.
                SafeArea(
                  child: Theme(
                    data: AppTheme.dark,
                    child: Builder(builder: _buildForm),
                  ),
                ),
              ],
            )
          : darkBackground
          ? Theme(
              data: AppTheme.dark,
              child: Builder(
                builder: (context) => AppBackground(
                  dense: true,
                  child: SafeArea(child: _buildForm(context)),
                ),
              ),
            )
          : AppBackground(
              dense: true,
              child: SafeArea(child: _buildForm(context)),
            ),
    );
  }
}

class AuthFooterPrompt extends StatelessWidget {
  const AuthFooterPrompt({
    required this.question,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final String question;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Flexible(
        child: Text(
          question,
          textAlign: TextAlign.end,
          style: context.textStyles.bodySmall,
        ),
      ),
      const SizedBox(width: AppSpacing.xs),
      AppButton.ghost(
        label: actionLabel,
        size: AppButtonSize.small,
        onPressed: onAction,
      ),
    ],
  );
}
