import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:flutter/material.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const BrandMark(size: BrandMarkSize.large),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.colors.textTertiary,
            ),
          ),
        ],
      ),
    ),
  );
}
