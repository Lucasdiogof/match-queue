import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/account/data/account_cache_store.dart';
import 'package:fifa_queue/features/account/domain/entities/account.dart';
import 'package:fifa_queue/features/account/domain/entities/platform.dart';
import 'package:fifa_queue/features/account/domain/repositories/account_repository.dart';
import 'package:fifa_queue/features/account/presentation/cubit/account_cubit.dart';
import 'package:fifa_queue/features/account/presentation/cubit/account_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAccountRepository implements AccountRepository {
  Account? account;
  AppFailure? failure;

  @override
  Future<Account> ensureMyAccount({required String fallbackDisplayName}) async {
    final error = failure;
    if (error != null) {
      throw error;
    }
    return account!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Account _account(String id, {String name = 'Lucas'}) => Account(
  id: id,
  displayName: name,
  platforms: const <Platform>[Platform.ps],
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 2),
);

void main() {
  late _FakeAccountRepository repository;
  late AccountCacheStore store;
  late AccountCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    repository = _FakeAccountRepository();
    store = AccountCacheStore(await SharedPreferences.getInstance());
    cubit = AccountCubit(repository, cacheStore: store);
  });

  tearDown(() => cubit.close());

  test('online load saves the account and shows fresh data', () async {
    repository.account = _account('u1');

    await cubit.load(fallbackDisplayName: 'x', userId: 'u1');
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.isFromCache, isFalse);
    expect(store.read('u1')!.value, _account('u1'));
  });

  test('offline with a saved account keeps showing it and records the '
      'failure', () async {
    await store.write(_account('u1', name: 'Saved'));
    repository.failure = const NetworkFailure();

    await cubit.load(fallbackDisplayName: 'x', userId: 'u1');

    expect(cubit.state.status, AccountStatus.ready);
    expect(cubit.state.account!.displayName, 'Saved');
    expect(cubit.state.isFromCache, isTrue);
    expect(cubit.state.failure, isA<NetworkFailure>());
  });

  test('offline without a saved account ends in failure, not empty', () async {
    repository.failure = const NetworkFailure();

    await cubit.load(fallbackDisplayName: 'x', userId: 'u1');

    expect(cubit.state.status, AccountStatus.failure);
    expect(cubit.state.account, isNull);
  });

  test('another user never sees the saved account', () async {
    await store.write(_account('u1'));
    repository.failure = const NetworkFailure();

    await cubit.load(fallbackDisplayName: 'x', userId: 'u2');

    expect(cubit.state.account, isNull);
  });

  test('clear on sign-out wipes the saved account', () async {
    await store.write(_account('u1'));

    cubit.clear();
    await Future<void>.delayed(Duration.zero);

    expect(store.read('u1'), isNull);
    expect(cubit.state.account, isNull);
  });
}
