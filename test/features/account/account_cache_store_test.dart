import 'package:fifa_queue/features/account/data/account_cache_store.dart';
import 'package:fifa_queue/features/account/domain/entities/account.dart';
import 'package:fifa_queue/features/account/domain/entities/platform.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Account _account(String id) => Account(
  id: id,
  displayName: 'Name $id',
  platforms: const <Platform>[Platform.ps],
  teamIds: const <String>['t1'],
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 2),
);

void main() {
  late AccountCacheStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    store = AccountCacheStore(await SharedPreferences.getInstance());
  });

  test('round-trips the stable account fields with the save time', () async {
    final savedAt = DateTime.utc(2026, 10, 15, 20);
    await store.write(_account('u1'), now: savedAt);

    final cached = store.read('u1');

    expect(cached, isNotNull);
    expect(cached!.value, _account('u1'));
    expect(cached.savedAt, savedAt);
  });

  test('never returns another user\'s account', () async {
    await store.write(_account('u1'));

    expect(store.read('u2'), isNull);
  });

  test('clear removes the cached account', () async {
    await store.write(_account('u1'));
    await store.clear();

    expect(store.read('u1'), isNull);
  });
}
