import 'package:fifa_queue/core/design_system/theme/theme_context_extensions.dart';
import 'package:fifa_queue/core/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// Header de conteudo para as telas principais do shell (Inicio, Times,
/// Controle, Historico) -- diferente do [AppAppBar], que continua cuidando
/// da barra de sistema (voltar, acoes). O [FeatureHeader] entra como
/// primeiro item do corpo rolavel, dando hierarquia de produto (eyebrow +
/// titulo + subtitulo curto + status/acao opcional) sem depender de sliver.
class FeatureHeader extends StatelessWidget {
  const FeatureHeader({
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (eyebrow != null) ...<Widget>[
                  Text(
                    eyebrow!.toUpperCase(),
                    // Sem verde: hierarquia aqui vem de tamanho, peso e
                    // espacamento de letra, nao de cor de destaque.
                    style: textStyles.labelSmall?.copyWith(
                      color: colors.textTertiary,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                ],
                Text(title, style: textStyles.headlineSmall),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle!,
                    style: textStyles.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
    );
  }
}
