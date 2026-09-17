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
    this.heroBackground = false,
    this.showWordmark = true,
    this.wordmark,
    this.contentAlignment,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final String? subtitle;
  final Widget? footer;
  final VoidCallback? onBack;
  final String? backTooltip;

  /// Telas "vitrine" (login, cadastro): fundo procedural rico -- o mesmo
  /// [AppBackground] nao-dense que o resto do app usa nas telas-hub, so com
  /// o halo tingido de acento. Recuperar senha e afins continuam com a
  /// variante minima (dense): sao fluxo secundario, nao a primeira
  /// impressao do produto.
  final bool heroBackground;

  /// Sem uso pratico hoje (a logo nunca vem mais embutida em arte nenhuma),
  /// mas mantido para telas que queiram esconder a wordmark por algum outro
  /// motivo futuro.
  final bool showWordmark;

  /// Sobrescreve o widget exibido quando [showWordmark] e true. Sem isso,
  /// cai no padrao (`MatchQueueWordmark`, desenhado em codigo). Uso pontual
  /// pra telas que querem outra variante da marca.
  final Widget? wordmark;

  /// Sobrescreve o alinhamento vertical do conteudo dentro do [Expanded].
  /// Sem isso, o padrao e centralizado.
  final Alignment? contentAlignment;

  Widget _buildForm(BuildContext context) => Stack(
    children: <Widget>[
      Column(
        children: <Widget>[
          Expanded(
            child: Align(
              alignment: contentAlignment ?? Alignment.center,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: AppContentContainer.form(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (showWordmark) ...<Widget>[
                        Center(child: wordmark ?? const MatchQueueWordmark()),
                        const SizedBox(height: AppSpacing.xxxl),
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
      ),
      // Posicionado por cima em vez de dentro da Column: um item de altura
      // fixa ali empurraria a logo pra baixo so na tela que tem back button
      // (cadastro), tirando a mesma altura de logo que login e cadastro
      // deveriam compartilhar (mesmo contentAlignment nos dois).
      if (onBack != null)
        Positioned(
          top: AppSpacing.sm,
          left: AppSpacing.sm,
          child: AppIconButton(
            icon: Icons.arrow_back,
            tooltip: backTooltip ?? '',
            onPressed: onBack,
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: AppBackground(
        dense: !heroBackground,
        glow: heroBackground ? colors.accent : null,
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
