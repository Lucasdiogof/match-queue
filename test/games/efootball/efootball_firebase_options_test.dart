import 'package:fifa_queue/games/efootball/efootball_firebase_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app Android do eFootball aponta pro projeto fifa-queue', () {
    expect(EfootballFirebaseOptions.android.projectId, 'fifa-queue');
    expect(
      EfootballFirebaseOptions.android.appId,
      '1:927848400584:android:7a07e89557b50579f187fd',
    );
  });

  test('app iOS do eFootball aponta pro bundle id próprio', () {
    expect(EfootballFirebaseOptions.ios.projectId, 'fifa-queue');
    expect(
      EfootballFirebaseOptions.ios.iosBundleId,
      'com.lucasdiogof.matchqueue.efootball',
    );
    expect(
      EfootballFirebaseOptions.ios.appId,
      '1:927848400584:ios:f4790db0cb90c8d2f187fd',
    );
  });
}
