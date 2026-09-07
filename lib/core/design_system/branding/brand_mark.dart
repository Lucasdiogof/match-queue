import 'package:fifa_queue/core/design_system/branding/brand_assets.dart';
import 'package:fifa_queue/core/design_system/theme/theme_context_extensions.dart';
import 'package:fifa_queue/core/design_system/tokens/app_radii.dart';
import 'package:fifa_queue/core/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

enum BrandMarkSize { small, medium, large }

class BrandMark extends StatelessWidget {
  const BrandMark({this.size = BrandMarkSize.medium, super.key});

  final BrandMarkSize size;

  double get _side => switch (size) {
    BrandMarkSize.small => 32,
    BrandMarkSize.medium => 48,
    BrandMarkSize.large => 72,
  };

  double get _fontSize => switch (size) {
    BrandMarkSize.small => 13,
    BrandMarkSize.medium => 18,
    BrandMarkSize.large => 27,
  };

  double get _radius => switch (size) {
    BrandMarkSize.small => AppRadii.sm,
    BrandMarkSize.medium => AppRadii.md,
    BrandMarkSize.large => AppRadii.lg,
  };

  @override
  Widget build(BuildContext context) {
    const logo = BrandAssets.logo;
    final colors = context.colors;

    if (logo != null) {
      // A arte tem fundo branco solido (nao e um simbolo com alpha) --
      // um badge arredondado com borda sutil deixa isso coerente tanto no
      // tema claro quanto no escuro, em vez de um quadrado branco cru sobre
      // fundo escuro.
      return Semantics(
        excludeSemantics: true,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: colors.borderSubtle),
              borderRadius: BorderRadius.circular(_radius),
            ),
            child: Image.asset(logo, width: _side, height: _side),
          ),
        ),
      );
    }

    return Semantics(
      label: BrandAssets.productName,
      child: Container(
        width: _side,
        height: _side,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.textPrimary,
          borderRadius: BorderRadius.circular(_radius),
        ),
        child: Text(
          BrandAssets.monogram,
          style: TextStyle(
            color: colors.background,
            fontSize: _fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({this.style, this.height = 24, super.key});

  final TextStyle? style;
  final double height;

  @override
  Widget build(BuildContext context) {
    const wordmark = BrandAssets.wordmark;
    if (wordmark != null) {
      // Ink-on-paper artwork, not a themeable asset: the letterforms are
      // themselves near-black, so cutting the background to transparent
      // makes it unreadable in dark mode instead of fixing anything. It
      // gets its own fixed light card -- deliberately not context.colors --
      // so it stays legible regardless of the app's ThemeMode.
      return Semantics(
        label: BrandAssets.productName,
        image: true,
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: context.colors.borderSubtle),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: height * 0.55,
                vertical: height * 0.35,
              ),
              child: Image.asset(wordmark, height: height),
            ),
          ),
        ),
      );
    }

    return Text(
      BrandAssets.productName,
      style: (style ?? context.textStyles.headlineSmall)?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: context.colors.textPrimary,
      ),
    );
  }
}

class BrandLockup extends StatelessWidget {
  const BrandLockup({
    this.markSize = BrandMarkSize.medium,
    this.axis = Axis.horizontal,
    super.key,
  });

  final BrandMarkSize markSize;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      BrandMark(size: markSize),
      const SizedBox(width: AppSpacing.md, height: AppSpacing.md),
      const BrandWordmark(),
    ];

    return axis == Axis.horizontal
        ? Row(mainAxisSize: MainAxisSize.min, children: children)
        : Column(mainAxisSize: MainAxisSize.min, children: children);
  }
}
