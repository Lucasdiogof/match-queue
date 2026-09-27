import 'package:fifa_queue/core/firebase/game_firebase_options.dart';
import 'package:fifa_queue/core/game/game_flavor_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EA FC resolve as FirebaseOptions do app já registrado', () {
    expect(
      () => GameFirebaseOptions.forGame(GameFlavorKey.eaFc),
      returnsNormally,
    );
  });

  test('eFootball resolve as FirebaseOptions do app já registrado', () {
    expect(
      () => GameFirebaseOptions.forGame(GameFlavorKey.efootball),
      returnsNormally,
    );
  });

  test('jogo sem app Firebase registrado falha alto e cedo em vez de herdar '
      'options de outro jogo', () {
    expect(
      () => GameFirebaseOptions.forGame(GameFlavorKey.ufl),
      throwsUnsupportedError,
    );
    expect(
      () => GameFirebaseOptions.forGame(GameFlavorKey.goals),
      throwsUnsupportedError,
    );
  });
}
