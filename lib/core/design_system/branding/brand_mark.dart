import 'package:fifa_queue/core/design_system/branding/brand_assets.dart';
import 'package:fifa_queue/core/design_system/theme/theme_context_extensions.dart';
import 'package:fifa_queue/core/design_system/tokens/app_radii.dart';
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
      // Sem ClipRRect nem borda: a arte ja e um badge fechado, com o proprio
      // arredondamento e o proprio fundo, e os cantos dela chegam vazados.
      // Recortar de novo somaria um segundo raio por cima do dela, e a borda
      // desenharia um contorno que nao acompanha a curva da arte. O embrulho
      // existia porque a arte anterior era um simbolo achatado sobre branco
      // -- sem ele virava um quadrado branco cru no tema escuro.
      return Semantics(
        excludeSemantics: true,
        child: Image.asset(logo, width: _side, height: _side),
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
