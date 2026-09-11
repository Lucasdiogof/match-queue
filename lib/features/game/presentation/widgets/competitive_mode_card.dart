import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Os dois modos competitivos do FC, como identidade VISUAL.
///
/// Nao substitui enum de dominio nenhum: internamente o modo continua sendo
/// Weekend League / Division Rivals. Isto aqui so decide cor.
enum CompetitiveMode { champions, rivals }

extension CompetitiveModeAccent on CompetitiveMode {
  /// Acento para uso FORA do card escuro (chip, badge), onde o fundo segue o
  /// tema. O dourado de Champions/Rivals e claro demais sobre branco, entao
  /// no tema claro cada modo cai no seu tom escuro.
  Color accentOn(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (this) {
      CompetitiveMode.champions =>
        isDark ? AppColors.championsGold : AppColors.championsWine,
      CompetitiveMode.rivals =>
        isDark ? AppColors.rivalsGold : AppColors.goldDeep,
    };
  }
}

/// Casca compartilhada dos cards de Champions e Rivals.
///
/// Existe para os dois terem identidade forte sem duplicar decoracao, e para
/// que o conteudo de cada um continue sendo problema do widget que ja sabe
/// buscar aquele dado -- este aqui nao conhece nem evento nem divisao.
///
/// Por que o card e escuro tambem no tema claro: Champions e Rivals sao
/// contexto, nao tema. Um bloco vinho-sobre-preto dentro de uma tela clara le
/// como inserto premium, que e exatamente a intencao -- e por isso ele e
/// compacto, para ser destaque e nao mancha.
class CompetitiveModeCard extends StatelessWidget {
  const CompetitiveModeCard({
    required this.mode,
    required this.title,
    required this.child,
    this.trailing,
    this.onTap,
    super.key,
  });

  final CompetitiveMode mode;
  final String title;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTap;

  Color get _gold => switch (mode) {
    CompetitiveMode.champions => AppColors.championsGold,
    CompetitiveMode.rivals => AppColors.rivalsGold,
  };

  Gradient get _background => switch (mode) {
    CompetitiveMode.champions => AppGradients.champions,
    CompetitiveMode.rivals => AppGradients.rivals,
  };

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    gradient: _background,
    // O dourado entra como aresta e texto, nunca dentro do gradiente: e o
    // que da leitura de metal sobre veludo em vez de degrade alaranjado.
    accent: AppCardAccent.top,
    accentGradient: AppGradients.goldEdge,
    borderColor: _gold.withValues(alpha: 0.35),
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.labelSmall?.copyWith(
                  color: _gold,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // O conteudo herda o claro do card escuro, entao quem usa nao
        // precisa repetir cor em cada Text.
        DefaultTextStyle.merge(
          style: const TextStyle(color: AppColors.darkTextPrimary),
          child: IconTheme.merge(
            data: IconThemeData(color: _gold),
            child: child,
          ),
        ),
      ],
    ),
  );
}

/// Linha "10 V · 3 D" e afins: rotulo apagado, numero forte.
class CompetitiveStat extends StatelessWidget {
  const CompetitiveStat({required this.value, required this.label, super.key});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textStyles.titleLarge?.copyWith(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
      Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textStyles.labelSmall?.copyWith(
          color: AppColors.darkTextSecondary,
          letterSpacing: 1.1,
        ),
      ),
    ],
  );
}
