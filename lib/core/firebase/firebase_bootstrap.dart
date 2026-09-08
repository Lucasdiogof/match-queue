import 'dart:async';

import 'package:fifa_queue/core/config/app_config.dart';
import 'package:fifa_queue/core/logging/app_logger.dart';
import 'package:fifa_queue/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fifa_queue/features/notifications/data/services/firebase_push_messaging_service.dart'
    show firebaseMessagingBackgroundHandler;
import 'package:flutter/foundation.dart';

enum FirebaseAvailability {
  /// FIREBASE_ENABLED=false: nunca tocamos no SDK.
  disabled,

  /// Habilitado, mas não inicializado nesta plataforma (Web/desktop por ora,
  /// ou falha na inicialização). O app segue com o fallback de push.
  unconfigured,

  /// Inicializado com sucesso; push via Firebase disponível.
  ready,
}

class FirebaseBootstrap {
  const FirebaseBootstrap(this._logger);

  final AppLogger _logger;

  /// Push só é oferecido em Android/iOS. Web depende de VAPID + service worker
  /// + HTTPS/domínio, ainda pendentes de propósito; desktop não tem push.
  static const Set<TargetPlatform> supportedPlatforms = <TargetPlatform>{
    TargetPlatform.android,
    TargetPlatform.iOS,
  };

  Future<FirebaseAvailability> initialize(AppConfig config) async {
    if (!config.firebaseEnabled) {
      _logger.info('Firebase desativado para ${config.environment.key}.');
      return FirebaseAvailability.disabled;
    }

    if (kIsWeb || !supportedPlatforms.contains(defaultTargetPlatform)) {
      _logger.info(
        'Firebase push habilitado só em Android/iOS por ora; '
        'plataforma atual segue sem push (fallback).',
      );
      return FirebaseAvailability.unconfigured;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // Handler de background precisa ser registrado antes do primeiro push;
      // é a função top-level (isolate próprio) do serviço de messaging.
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _wireCrashlytics();
      _logger.info('Firebase inicializado (${config.environment.key}).');
      return FirebaseAvailability.ready;
    } on Object catch (error, stackTrace) {
      // Push é conveniência: se o Firebase não subir, o app continua inteiro
      // com o fallback. Nunca deixamos isso derrubar o arranque.
      _logger.error(
        'Falha ao inicializar Firebase; seguindo sem push.',
        error: error,
        stackTrace: stackTrace,
      );
      return FirebaseAvailability.unconfigured;
    }
  }

  void _wireCrashlytics() {
    final crashlytics = FirebaseCrashlytics.instance;
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      previousOnError?.call(details);
      crashlytics.recordFlutterError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }
}
