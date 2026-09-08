import 'package:fifa_queue/core/firebase/firebase_bootstrap.dart';
import 'package:fifa_queue/core/logging/app_logger.dart';
import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/notifications/application/push_token_coordinator.dart';
import 'package:fifa_queue/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:fifa_queue/features/notifications/data/repositories/local_notification_repository.dart';
import 'package:fifa_queue/features/notifications/data/repositories/supabase_notification_repository.dart';
import 'package:fifa_queue/features/notifications/data/services/firebase_push_messaging_service.dart';
import 'package:fifa_queue/features/notifications/data/services/unavailable_push_messaging_service.dart';
import 'package:fifa_queue/features/notifications/domain/entities/push_permission_status.dart';
import 'package:fifa_queue/features/notifications/domain/repositories/notification_repository.dart';
import 'package:fifa_queue/features/notifications/domain/services/push_messaging_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void registerNotificationsModule(
  GetIt sl, {
  required SupabaseClient? supabaseClient,
  required FirebaseAvailability firebaseAvailability,
}) {
  sl
    ..registerLazySingleton<PushMessagingService>(
      _pushMessagingService(firebaseAvailability),
    )
    ..registerLazySingleton<NotificationRepository>(
      _notificationRepository(sl, supabaseClient),
    )
    ..registerLazySingleton<PushTokenCoordinator>(
      () => PushTokenCoordinator(
        sl<PushMessagingService>(),
        sl<NotificationRepository>(),
        sl<AppLogger>(),
      ),
    );
}

PushMessagingService Function() _pushMessagingService(
  FirebaseAvailability availability,
) {
  // Firebase real só quando inicializou de fato. Web/desktop e qualquer falha
  // de init caem no fallback, que se comporta honestamente como "sem push".
  if (availability == FirebaseAvailability.ready && !kIsWeb) {
    return () => FirebasePushMessagingService(FirebaseMessaging.instance);
  }
  return () => UnavailablePushMessagingService(_currentPlatform());
}

NotificationRepository Function() _notificationRepository(
  GetIt sl,
  SupabaseClient? supabaseClient,
) {
  if (supabaseClient == null) {
    return LocalNotificationRepository.new;
  }
  return () => SupabaseNotificationRepository(
    SupabaseNotificationRemoteDataSource(supabaseClient),
    sl<SupabaseErrorMapper>(),
  );
}

DevicePlatform _currentPlatform() {
  if (kIsWeb) {
    return DevicePlatform.web;
  }
  return defaultTargetPlatform == TargetPlatform.iOS
      ? DevicePlatform.ios
      : DevicePlatform.android;
}
