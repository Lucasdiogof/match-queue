import 'package:fifa_queue/core/design_system/layout/app_responsive.dart';
import 'package:fifa_queue/core/design_system/tokens/app_breakpoints.dart';
import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.constrainContent = true,
    this.maxContentWidth = AppBreakpoints.maxContentWidth,
    this.applyHorizontalGutter = true,
    this.resizeToAvoidBottomInset = true,
    super.key,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool constrainContent;
  final double maxContentWidth;
  final bool applyHorizontalGutter;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: appBar,
    bottomNavigationBar: bottomNavigationBar,
    floatingActionButton: floatingActionButton,
    resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    body: SafeArea(
      child: constrainContent
          ? AppContentContainer(
              maxWidth: maxContentWidth,
              padding: applyHorizontalGutter ? null : EdgeInsets.zero,
              child: body,
            )
          : body,
    ),
  );
}
