import 'package:fifa_queue/core/design_system/theme/theme_context_extensions.dart';
import 'package:fifa_queue/core/design_system/tokens/app_breakpoints.dart';
import 'package:fifa_queue/core/design_system/tokens/app_radii.dart';
import 'package:fifa_queue/core/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool isScrollControlled = true,
}) => showModalBottomSheet<T>(
  context: context,
  isDismissible: isDismissible,
  isScrollControlled: isScrollControlled,
  useSafeArea: true,
  constraints: const BoxConstraints(
    maxWidth: AppBreakpoints.maxBottomSheetWidth,
  ),
  builder: builder,
);

class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    required this.child,
    this.title,
    this.subtitle,
    this.actions = const <Widget>[],
    super.key,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.borderStrong,
                  borderRadius: AppRadii.borderPill,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (title != null)
                    Text(title!, style: context.textStyles.headlineSmall),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    Text(subtitle!, style: context.textStyles.bodyMedium),
                  ],
                  if (title != null || subtitle != null)
                    const SizedBox(height: AppSpacing.xl),
                  child,
                  if (actions.isNotEmpty) ...<Widget>[
                    const SizedBox(height: AppSpacing.xl),
                    ...actions,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
