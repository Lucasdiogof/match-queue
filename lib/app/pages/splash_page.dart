import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// A splash nativa (android/, ios/) e branca -- essa e a primeira tela que
/// o Flutter de fato desenha, entao ela fica presa ao mesmo branco em vez
/// de seguir ThemeMode. Se seguisse o tema escuro, quem estivesse em dark
/// veria a splash nativa branca virar preta de repente assim que o Flutter
/// assume, exatamente o flash que a Etapa 4.5 pediu para evitar.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Colors.white,
    child: Center(
      child: _SplashContent(),
    ),
  );
}

class _SplashContent extends StatelessWidget {
  const _SplashContent();

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      if (BrandAssets.hasSplashMark)
        Semantics(
          label: BrandAssets.productName,
          image: true,
          child: ExcludeSemantics(
            child: Image.asset(BrandAssets.splashMark!, width: 220),
          ),
        )
      else
        const BrandLockup(markSize: BrandMarkSize.large, axis: Axis.vertical),
      const SizedBox(height: AppSpacing.xxl),
      const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black45),
      ),
    ],
  );
}
