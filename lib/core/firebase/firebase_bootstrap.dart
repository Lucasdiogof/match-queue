import 'dart:async';

import 'package:fifa_queue/core/config/app_config.dart';
import 'package:fifa_queue/core/logging/app_logger.dart';
import 'package:fifa_queue/firebase_options.dart';
import 'package:fifa_queue/l10n/generated/app_localizations.dart';
import 'package:fifa_queue/l10n/generated/app_localizations_en.dart';
import 'package:fifa_queue/l10n/generated/app_localizations_es.dart';
import 'package:fifa_queue/l10n/generated/app_localizations_pt.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fifa_queue/features/notifications/data/services/firebase_push_messaging_service.dart'
    show firebaseMessagingBackgroundHandler;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

  /// A Edge Function do worker (supabase/functions/process-notification-outbox)
  /// endereça toda notificação Android a este id fixo. Mudar aqui sem mudar
  /// lá (ou vice-versa) faz o FCM aceitar a entrega e o Android descartar a
  /// notificação em silêncio -- nenhum dos dois lados reporta erro nesse caso.
  static const String queueAlertsChannelId = 'queue_alerts';

  /// Canal dos 6 tipos sociais/esportivos da Etapa 15 (time, ranking,
  /// Weekend League, Rivals) -- prioridade normal, sem o urgencia de
  /// "sua vez": ninguem perde nada se abrir o app 10 minutos depois.
  static const String appUpdatesChannelId = 'app_updates';

  Future<FirebaseAvailability> initialize(
    AppConfig config, {
    Locale locale = const Locale('en'),
  }) async {
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
      // Precisa existir ANTES do primeiro push chegar: se a primeira
      // notificação for entregue antes do canal existir, o Android (8+) a
      // descarta em silêncio em vez de criar um canal padrão.
      await _ensureAndroidNotificationChannel(locale);
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

  /// Canais são um conceito só do Android; no iOS este método nunca é
  /// chamado de verdade (o guard abaixo cobre até uma futura mudança em
  /// supportedPlatforms). Idempotente pela própria API do Android: chamar de
  /// novo com o mesmo id não duplica nem falha, o sistema ignora se já
  /// existir -- não precisa de checagem manual de duplicata aqui.
  Future<void> _ensureAndroidNotificationChannel(Locale locale) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    final l10n = _lookupL10n(locale);
    final plugin = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await plugin?.createNotificationChannel(
      AndroidNotificationChannel(
        queueAlertsChannelId,
        l10n.notificationsChannelQueueAlertsName,
        description: l10n.notificationsChannelQueueAlertsDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
    await plugin?.createNotificationChannel(
      AndroidNotificationChannel(
        appUpdatesChannelId,
        l10n.notificationsChannelAppUpdatesName,
        description: l10n.notificationsChannelAppUpdatesDescription,
        importance: Importance.defaultImportance,
      ),
    );
  }

  AppLocalizations _lookupL10n(Locale locale) => switch (locale.languageCode) {
    'pt' => AppLocalizationsPt(),
    'es' => AppLocalizationsEs(),
    _ => AppLocalizationsEn(),
  };

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
