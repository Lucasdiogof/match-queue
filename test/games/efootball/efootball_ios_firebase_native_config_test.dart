import 'dart:convert';
import 'dart:io';

import 'package:fifa_queue/games/efootball/efootball_firebase_options.dart';
import 'package:flutter_test/flutter_test.dart';

// Regressão: o eFootball não pode sair com o GoogleService-Info.plist nem
// com o upload de símbolos do Crashlytics do EA FC (docs/game_flavors.md).
// Confere a configuração nativa versionada; os plists em si ficam fora do git.
void main() {
  final pbxproj = File(
    'ios/Runner.xcodeproj/project.pbxproj',
  ).readAsStringSync();

  test('plist não é mais empacotado estaticamente (Resources)', () {
    expect(pbxproj, isNot(contains('GoogleService-Info.plist in Resources')));
  });

  test('build phase copia o plist do bundle id do target e valida', () {
    expect(
      pbxproj,
      contains(
        r'Runner/Firebase/${PRODUCT_BUNDLE_IDENTIFIER}/GoogleService-Info.plist',
      ),
    );
    expect(pbxproj, contains("PlistBuddy -c 'Print :BUNDLE_ID'"));
  });

  test('upload de símbolos do Crashlytics escolhe o app por configuração', () {
    expect(pbxproj, contains(r'--build-configuration=\"${CONFIGURATION}\"'));
    expect(pbxproj, isNot(contains('--default-config=default')));
  });

  test('firebase.json aponta cada configuração eFootball pro app eFootball', () {
    final json =
        jsonDecode(File('firebase.json').readAsStringSync())
            as Map<String, dynamic>;
    final flutter = json['flutter'] as Map<String, dynamic>;
    final platforms = flutter['platforms'] as Map<String, dynamic>;
    final ios = platforms['ios'] as Map<String, dynamic>;
    final configs = ios['buildConfigurations'] as Map<String, dynamic>;

    for (final name in [
      'Debug-efootball',
      'Release-efootball',
      'Profile-efootball',
    ]) {
      final config = configs[name] as Map<String, dynamic>;
      expect(config['appId'], EfootballFirebaseOptions.ios.appId, reason: name);
      expect(
        config['fileOutput'],
        'ios/Runner/Firebase/com.lucasdiogof.matchqueue.efootball/GoogleService-Info.plist',
        reason: name,
      );
    }
    for (final name in ['Debug', 'Release', 'Profile']) {
      expect(
        (configs[name] as Map)['appId'],
        isNot(EfootballFirebaseOptions.ios.appId),
        reason: name,
      );
    }
  });
}
