import 'package:fifa_queue/core/game/game_flavor_key.dart';
import 'package:fifa_queue/firebase_options.dart' as ea_fc;
import 'package:fifa_queue/games/efootball/efootball_firebase_options.dart'
    as efootball;
import 'package:firebase_core/firebase_core.dart';

/// Cada jogo tem seu proprio app Firebase (mesmo projeto `fifa-queue` do
/// console, apps Android/iOS separados por bundle id/package) -- nunca as
/// mesmas `FirebaseOptions` de outro jogo. Jogos sem app Firebase
/// registrado ainda falham alto e cedo em vez de silenciosamente
/// inicializar com apiKey/appId de outro jogo.
class GameFirebaseOptions {
  const GameFirebaseOptions._();

  static FirebaseOptions forGame(GameFlavorKey game) {
    switch (game) {
      case GameFlavorKey.eaFc:
        return ea_fc.DefaultFirebaseOptions.currentPlatform;
      case GameFlavorKey.efootball:
        return efootball.EfootballFirebaseOptions.currentPlatform;
      case GameFlavorKey.ufl:
      case GameFlavorKey.goals:
        throw UnsupportedError(
          'Firebase ainda nao foi configurado para o flavor "${game.key}". '
          'Registre os apps Android/iOS no Firebase Console (mesmo projeto '
          'fifa-queue), rode flutterfire configure (ou adicione as options '
          'aqui manualmente) antes de habilitar FIREBASE_ENABLED=true para '
          'este jogo.',
        );
    }
  }
}
