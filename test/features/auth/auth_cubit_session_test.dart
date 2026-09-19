import 'dart:async';

import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/auth/domain/entities/auth_snapshot.dart';
import 'package:fifa_queue/features/auth/domain/entities/auth_user.dart';
import 'package:fifa_queue/features/auth/domain/repositories/auth_repository.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

const AuthUser _testUser = AuthUser(id: 'u1', email: 'a@b.com');

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({AuthUser? user = _testUser}) : _user = user;

  AuthUser? _user;
  final StreamController<AuthSnapshot> _stream =
      StreamController<AuthSnapshot>.broadcast();

  bool expiring = false;
  Object? refreshError;
  Completer<void>? refreshGate;
  int refreshCalls = 0;
  int signOutCalls = 0;

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthSnapshot> watchAuthState() => _stream.stream;

  @override
  bool get isSessionExpiring => expiring;

  @override
  Future<void> refreshSession() async {
    refreshCalls++;
    await refreshGate?.future;
    final error = refreshError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _user = null;
    _stream.add(const AuthSnapshot.signedOut());
  }

  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeAuthRepository repository;
  late StreamController<void> signal;
  late AuthCubit cubit;

  setUp(() {
    repository = _FakeAuthRepository();
    signal = StreamController<void>.broadcast();
    cubit = AuthCubit(repository, sessionExpired: signal.stream)..initialize();
  });

  tearDown(() async {
    await cubit.close();
    await signal.close();
  });

  group('sinal de sessao expirada', () {
    test('refresh com sucesso mantem o usuario logado', () async {
      signal.add(null);
      await _settle();

      expect(repository.refreshCalls, 1);
      expect(repository.signOutCalls, 0);
      expect(cubit.state.status, AuthStatus.authenticated);
    });

    test('token invalido desloga e deixa o aviso de sessao expirada', () async {
      repository.refreshError = const AuthFailure(
        reason: AuthFailureReason.sessionExpired,
      );

      signal.add(null);
      await _settle();

      expect(repository.signOutCalls, 1);
      expect(cubit.state.status, AuthStatus.unauthenticated);
      expect(
        cubit.state.failure,
        const AuthFailure(reason: AuthFailureReason.sessionExpired),
      );
    });

    test('sem rede NAO desloga', () async {
      repository.refreshError = const NetworkFailure();

      signal.add(null);
      await _settle();

      expect(repository.signOutCalls, 0);
      expect(cubit.state.status, AuthStatus.authenticated);
    });

    test('timeout tambem NAO desloga', () async {
      repository.refreshError = const TimeoutFailure();

      signal.add(null);
      await _settle();

      expect(repository.signOutCalls, 0);
      expect(cubit.state.status, AuthStatus.authenticated);
    });

    test('sinais durante uma recuperacao em curso sao ignorados', () async {
      repository.refreshGate = Completer<void>();

      signal
        ..add(null)
        ..add(null)
        ..add(null);
      await _settle();
      expect(repository.refreshCalls, 1);

      repository.refreshGate!.complete();
      await _settle();
      expect(repository.refreshCalls, 1);
    });

    test('deslogado nao tenta renovar', () async {
      await cubit.close();
      repository = _FakeAuthRepository(user: null);
      cubit = AuthCubit(repository, sessionExpired: signal.stream)
        ..initialize();

      signal.add(null);
      await _settle();

      expect(repository.refreshCalls, 0);
    });
  });

  group('refreshSessionIfNeeded (volta do segundo plano)', () {
    test('token longe de vencer: nao faz nada', () async {
      repository.expiring = false;

      await cubit.refreshSessionIfNeeded();

      expect(repository.refreshCalls, 0);
    });

    test('token vencido ou quase: renova', () async {
      repository.expiring = true;

      await cubit.refreshSessionIfNeeded();

      expect(repository.refreshCalls, 1);
      expect(cubit.state.status, AuthStatus.authenticated);
    });

    test('token vencido e refresh recusado: desloga com aviso', () async {
      repository.expiring = true;
      repository.refreshError = const AuthFailure(
        reason: AuthFailureReason.sessionExpired,
      );

      await cubit.refreshSessionIfNeeded();

      expect(cubit.state.status, AuthStatus.unauthenticated);
      expect(cubit.state.failure, isA<AuthFailure>());
    });
  });
}
