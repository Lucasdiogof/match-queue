import 'package:fifa_queue/core/design_system/theme/theme_context_extensions.dart';
import 'package:fifa_queue/core/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class AppLoading extends StatelessWidget {
  const AppLoading({this.message, this.size = 28, super.key});

  const AppLoading.inline({this.message, super.key}) : size = 18;

  final String? message;
  final double size;

  @override
  Widget build(BuildContext context) {
    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: size > 20 ? 2.5 : 2,
        color: context.colors.textPrimary,
      ),
    );

    if (message == null) {
      return Center(child: indicator);
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          indicator,
          const SizedBox(height: AppSpacing.lg),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: context.textStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
