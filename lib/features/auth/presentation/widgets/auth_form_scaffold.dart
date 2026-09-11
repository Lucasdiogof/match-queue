import 'package:fifa_queue/core/design_system/design_system.dart';
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
    super.key,
  });

  final String title;
  final List<Widget> children;
  final String? subtitle;
  final Widget? footer;
  final VoidCallback? onBack;
  final String? backTooltip;

  /// Imagem de fundo em tela cheia (ex.: foto de estadio com o wordmark ja
  /// aplicado). Quando presente, o formulario e alinhado ao rodape em vez de
  /// centralizado, para nao cobrir a arte.
  final String? backgroundImage;

  /// Quando [backgroundImage] ja traz o wordmark embutido na arte, o
  /// BrandWordmark widget e desnecessario (ficaria duplicado/ilegivel sobre
  /// a foto).
  final bool showWordmark;

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
          alignment: backgroundImage != null
              ? const Alignment(0, 0.45)
              : Alignment.center,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: AppContentContainer.form(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (showWordmark) ...<Widget>[
                    const BrandWordmark(height: 76),
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

  @override
  Widget build(BuildContext context) => Scaffold(
    body: backgroundImage != null
        ? Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.asset(backgroundImage!, fit: BoxFit.cover),
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
        : AppBackground(
            dense: true,
            child: SafeArea(child: _buildForm(context)),
          ),
  );
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
