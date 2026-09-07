import 'package:fifa_queue/core/config/app_config.dart';
import 'package:flutter/widgets.dart';

class AppConfigScope extends InheritedWidget {
  const AppConfigScope({required this.config, required super.child, super.key});

  final AppConfig config;

  static AppConfig of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppConfigScope>();
    assert(scope != null, 'AppConfigScope não encontrado acima deste widget.');
    return scope!.config;
  }

  @override
  bool updateShouldNotify(AppConfigScope oldWidget) =>
      oldWidget.config != config;
}
