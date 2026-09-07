import 'package:fifa_queue/core/config/app_config.dart';
import 'package:fifa_queue/core/logging/app_logger.dart';
import 'package:flutter/foundation.dart';

enum FirebaseAvailability { disabled, unconfigured, ready }

class FirebaseBootstrap {
  const FirebaseBootstrap(this._logger);

  final AppLogger _logger;

  static const Set<TargetPlatform> supportedPlatforms = <TargetPlatform>{
    TargetPlatform.android,
    TargetPlatform.iOS,
  };

  Future<FirebaseAvailability> initialize(AppConfig config) async {
    if (!config.firebaseEnabled) {
      _logger.info('Firebase desativado para ${config.environment.key}.');
      return FirebaseAvailability.disabled;
    }
    _logger.warning(
      'FIREBASE_ENABLED=true, mas nenhum projeto Firebase foi vinculado ainda. '
      'Messaging, Crashlytics e Analytics seguem como no-op.',
    );
    return FirebaseAvailability.unconfigured;
  }
}
