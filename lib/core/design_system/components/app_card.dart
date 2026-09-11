import 'package:fifa_queue/core/design_system/theme/theme_context_extensions.dart';
import 'package:fifa_queue/core/design_system/tokens/app_radii.dart';
import 'package:fifa_queue/core/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

enum AppCardVariant { surface, elevated, outlined }

/// Onde a faixa de acento encosta no card.
enum AppCardAccent { none, top, left }

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.variant = AppCardVariant.surface,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.borderColor,
    this.accent = AppCardAccent.none,
    this.accentColor,
    this.accentGradient,
    this.gradient,
    super.key,
  });

  final Widget child;
  final AppCardVariant variant;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;

  /// Faixa fina de acento. Opcional de proposito: se todo card tivesse uma,
  /// ela deixaria de significar "este e diferente".
  final AppCardAccent accent;
  final Color? accentColor;
  final Gradient? accentGradient;

  /// Substitui a superficie plana. Reservado a card de identidade propria
  /// (Champions, Rivals) -- nao usar como fundo de card comum.
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final background = switch (variant) {
      AppCardVariant.surface => colors.surface,
      AppCardVariant.elevated => colors.surfaceElevated,
      AppCardVariant.outlined => Colors.transparent,
    };
    final stripe = accentGradient == null
        ? BoxDecoration(color: accentColor ?? colors.accent)
        : BoxDecoration(gradient: accentGradient);

    return Material(
      color: gradient == null ? background : Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.borderLg,
        side: BorderSide(color: borderColor ?? colors.borderSubtle),
      ),
      child: Ink(
        decoration: gradient == null ? null : BoxDecoration(gradient: gradient),
        child: InkWell(
          onTap: onTap,
          child: switch (accent) {
            AppCardAccent.none => Padding(padding: padding, child: child),
            AppCardAccent.top => Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DecoratedBox(
                  decoration: stripe,
                  child: const SizedBox(height: 3, width: double.infinity),
                ),
                Padding(padding: padding, child: child),
              ],
            ),
            AppCardAccent.left => IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  DecoratedBox(
                    decoration: stripe,
                    child: const SizedBox(width: 3),
                  ),
                  Expanded(child: Padding(padding: padding, child: child)),
                ],
              ),
            ),
          },
        ),
      ),
    );
  }
}
