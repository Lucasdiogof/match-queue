import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// App Firebase do eFootball -- mesmo projeto `fifa-queue` do EA FC, apps
/// Android/iOS próprios registrados no Firebase Console (ver
/// docs/game_flavors.md). Só Android/iOS existem hoje; o eFootball não tem
/// build Web ainda, então não há app Web registrado.
class EfootballFirebaseOptions {
  const EfootballFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Firebase do eFootball ainda não tem app Web registrado no '
        'Firebase Console.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Firebase do eFootball só está configurado para Android/iOS.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBQTgT9bkXeqQ_6ae31xVj2GvwkP5sJOcw',
    appId: '1:927848400584:android:7a07e89557b50579f187fd',
    messagingSenderId: '927848400584',
    projectId: 'fifa-queue',
    storageBucket: 'fifa-queue.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAEIEtBVfphfOn9zgAj3LZs_H8C49ou4pc',
    appId: '1:927848400584:ios:f4790db0cb90c8d2f187fd',
    messagingSenderId: '927848400584',
    projectId: 'fifa-queue',
    storageBucket: 'fifa-queue.firebasestorage.app',
    iosBundleId: 'com.lucasdiogof.matchqueue.efootball',
  );
}
