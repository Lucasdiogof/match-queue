import 'package:fifa_queue/core/logging/app_logger.dart';

abstract interface class CrashReporter {
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
  });

  Future<void> setUserIdentifier(String? userId);

  Future<void> leaveBreadcrumb(String message);
}

class LoggingCrashReporter implements CrashReporter {
  const LoggingCrashReporter(this._logger);

  final AppLogger _logger;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
  }) async {
    _logger.error(
      fatal ? 'Erro fatal capturado' : 'Erro capturado',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  Future<void> setUserIdentifier(String? userId) async {
    _logger.debug('CrashReporter.userId=${userId ?? 'null'}');
  }

  @override
  Future<void> leaveBreadcrumb(String message) async {
    _logger.debug('breadcrumb: $message');
  }
}
