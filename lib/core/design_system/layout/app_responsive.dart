import 'package:fifa_queue/core/design_system/tokens/app_breakpoints.dart';
import 'package:fifa_queue/core/design_system/tokens/app_spacing.dart';
import 'package:flutter/widgets.dart';

enum AppScreenSize {
  mobile,
  tablet,
  desktop;

  static AppScreenSize fromWidth(double width) {
    if (width >= AppBreakpoints.desktop) {
      return AppScreenSize.desktop;
    }
    if (width >= AppBreakpoints.tablet) {
      return AppScreenSize.tablet;
    }
    return AppScreenSize.mobile;
  }

  bool get isMobile => this == AppScreenSize.mobile;

  bool get isTablet => this == AppScreenSize.tablet;

  bool get isDesktop => this == AppScreenSize.desktop;

  bool get isCompact => this == AppScreenSize.mobile;

  bool get isExpanded => this != AppScreenSize.mobile;
}

extension AppResponsiveX on BuildContext {
  AppScreenSize get screenSize =>
      AppScreenSize.fromWidth(MediaQuery.sizeOf(this).width);

  bool get isMobile => screenSize.isMobile;

  bool get isDesktop => screenSize.isDesktop;

  T responsive<T>({required T mobile, T? tablet, T? desktop}) =>
      switch (screenSize) {
        AppScreenSize.mobile => mobile,
        AppScreenSize.tablet => tablet ?? mobile,
        AppScreenSize.desktop => desktop ?? tablet ?? mobile,
      };

  double get horizontalGutter => responsive(
    mobile: AppSpacing.lg,
    tablet: AppSpacing.xl,
    desktop: AppSpacing.xxl,
  );
}

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.mobile,
    this.tablet,
    this.desktop,
    super.key,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = AppScreenSize.fromWidth(constraints.maxWidth);
      final builder = switch (size) {
        AppScreenSize.mobile => mobile,
        AppScreenSize.tablet => tablet ?? mobile,
        AppScreenSize.desktop => desktop ?? tablet ?? mobile,
      };
      return builder(context);
    },
  );
}

class AppContentContainer extends StatelessWidget {
  const AppContentContainer({
    required this.child,
    this.maxWidth = AppBreakpoints.maxContentWidth,
    this.padding,
    super.key,
  });

  const AppContentContainer.narrow({
    required this.child,
    this.padding,
    super.key,
  }) : maxWidth = AppBreakpoints.maxNarrowContentWidth;

  const AppContentContainer.form({required this.child, this.padding, super.key})
    : maxWidth = AppBreakpoints.maxFormWidth;

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Padding(
        padding:
            padding ??
            EdgeInsets.symmetric(horizontal: context.horizontalGutter),
        child: child,
      ),
    ),
  );
}
