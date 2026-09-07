import 'package:fifa_queue/core/design_system/theme/theme_context_extensions.dart';
import 'package:fifa_queue/core/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    this.title,
    this.subtitle,
    this.leading,
    this.actions = const <Widget>[],
    this.showDivider = false,
    super.key,
  });

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final bool showDivider;

  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 56 : 72);

  @override
  Widget build(BuildContext context) => AppBar(
    leading: leading,
    automaticallyImplyLeading: leading == null,
    toolbarHeight: preferredSize.height,
    titleSpacing: AppSpacing.lg,
    title: title == null
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(title!, style: context.textStyles.titleLarge),
              if (subtitle != null)
                Text(subtitle!, style: context.textStyles.bodySmall),
            ],
          ),
    actions: <Widget>[
      ...actions,
      const SizedBox(width: AppSpacing.sm),
    ],
    bottom: showDivider
        ? PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: context.colors.borderSubtle),
          )
        : null,
  );
}
