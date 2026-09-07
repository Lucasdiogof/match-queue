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
    if (logo != null) {
      return Image.asset(logo, width: _side, height: _side);
    }

    final colors = context.colors;
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
  const BrandWordmark({this.style, super.key});

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    const wordmark = BrandAssets.wordmark;
    if (wordmark != null) {
      return Image.asset(wordmark, height: 24);
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
