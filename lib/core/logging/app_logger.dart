import 'dart:developer' as developer;

enum LogLevel { debug, info, warning, error }

abstract interface class AppLogger {
  void debug(String message);

  void info(String message);

  void warning(String message, {Object? error, StackTrace? stackTrace});

  void error(String message, {Object? error, StackTrace? stackTrace});
}

class ConsoleAppLogger implements AppLogger {
  const ConsoleAppLogger({this.minimumLevel = LogLevel.debug});

  final LogLevel minimumLevel;

  static const String _name = 'fifa_queue';

  @override
  void debug(String message) => _write(LogLevel.debug, message);

  @override
  void info(String message) => _write(LogLevel.info, message);

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) =>
      _write(LogLevel.warning, message, error: error, stackTrace: stackTrace);

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _write(LogLevel.error, message, error: error, stackTrace: stackTrace);

  void _write(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < minimumLevel.index) {
      return;
    }
    developer.log(
      '[${level.name.toUpperCase()}] ${LogSanitizer.sanitize(message)}',
      name: _name,
      error: error == null ? null : LogSanitizer.sanitize('$error'),
      stackTrace: stackTrace,
    );
  }
}

class SilentAppLogger implements AppLogger {
  const SilentAppLogger();

  @override
  void debug(String message) {}

  @override
  void info(String message) {}

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {}
}

class LogSanitizer {
  const LogSanitizer._();

  static final RegExp _jsonWebToken = RegExp(
    r'eyJ[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+',
  );
  static final RegExp _bearer = RegExp(
    r'bearer\s+[A-Za-z0-9._\-]+',
    caseSensitive: false,
  );
  static final RegExp _email = RegExp(
    r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}',
  );

  static String sanitize(String input) => input
      .replaceAll(_jsonWebToken, '<redacted:jwt>')
      .replaceAll(_bearer, '<redacted:bearer>')
      .replaceAll(_email, '<redacted:email>');
}
