import 'package:fifa_queue/games/efootball/efootball_game_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('eFootball só habilita o core compartilhado', () {
    final capabilities = efootballGameConfig.capabilities;

    expect(capabilities.teams, isTrue);
    expect(capabilities.matchmaking, isTrue);
    expect(capabilities.history, isTrue);
  });

  test('eFootball não herda features específicas do EA FC', () {
    final capabilities = efootballGameConfig.capabilities;

    expect(capabilities.squads, isFalse);
    expect(capabilities.cards, isFalse);
    expect(capabilities.market, isFalse);
    expect(capabilities.playStyles, isFalse);
    expect(capabilities.chemistry, isFalse);
    expect(capabilities.evolutions, isFalse);
    expect(capabilities.controlsGuide, isFalse);
  });

  test('eFootball não inventa game modes ainda', () {
    expect(efootballGameConfig.gameModes, isEmpty);
  });

  test('eFootball espera o scheme próprio, nunca o do EA FC', () {
    expect(
      efootballGameConfig.expectedUrlScheme,
      'com.lucasdiogof.matchqueue.efootball',
    );
  });

  test('eFootball espera o applicationId/bundle id próprio', () {
    expect(efootballGameConfig.expectedPackageIdentifiers, <String>{
      'com.lucasdiogof.matchqueue.efootball',
    });
  });

  test('eFootball ainda não tem projeto Supabase próprio conhecido', () {
    expect(efootballGameConfig.expectedSupabaseProjectRef, isNull);
  });
}
