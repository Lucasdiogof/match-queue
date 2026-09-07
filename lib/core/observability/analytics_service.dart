import 'package:fifa_queue/core/logging/app_logger.dart';

abstract interface class AnalyticsService {
  Future<void> logEvent(String name, {Map<String, Object?>? parameters});

  Future<void> setCurrentScreen(String screenName);

  Future<void> setUserIdentifier(String? userId);
}

class LoggingAnalyticsService implements AnalyticsService {
  const LoggingAnalyticsService(this._logger);

  final AppLogger _logger;

  @override
  Future<void> logEvent(String name, {Map<String, Object?>? parameters}) async {
    _logger.debug(
      'analytics: $name ${parameters ?? const <String, Object?>{}}',
    );
  }

  @override
  Future<void> setCurrentScreen(String screenName) async {
    _logger.debug('analytics: screen=$screenName');
  }

  @override
  Future<void> setUserIdentifier(String? userId) async {
    _logger.debug('analytics: userId=${userId ?? 'null'}');
  }
}
