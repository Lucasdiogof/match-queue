import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/supabase/session_expired_signal.dart';
import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late SessionExpiredSignal signal;
  late SupabaseErrorMapper mapper;
  late int notifications;

  setUp(() {
    signal = SessionExpiredSignal();
    mapper = SupabaseErrorMapper(sessionExpiredSignal: signal);
    notifications = 0;
    signal.stream.listen((_) => notifications++);
  });

  Future<void> pump() => Future<void>.delayed(Duration.zero);

  void expectSessionExpired(Object error) {
    final failure = mapper.map(error);
    expect(failure, isA<AuthFailure>());
    expect((failure as AuthFailure).reason, AuthFailureReason.sessionExpired);
  }

  group('sessao expirada', () {
    test('AuthException 401 sem codigo', () {
      expectSessionExpired(const AuthException('x', statusCode: '401'));
    });

    test('AuthException 403 sem codigo', () {
      expectSessionExpired(const AuthException('x', statusCode: '403'));
    });

    test('mensagem de JWT invalido', () {
      expectSessionExpired(const AuthException('invalid JWT: expired'));
    });

    test('AuthSessionMissingException', () {
      expectSessionExpired(AuthSessionMissingException());
    });

    test('Postgrest PGRST301 e PGRST303', () {
      expectSessionExpired(
        const PostgrestException(message: 'x', code: 'PGRST301'),
      );
      expectSessionExpired(
        const PostgrestException(message: 'x', code: 'PGRST303'),
      );
    });

    test('Storage 401 e Storage com JWT na mensagem', () {
      expectSessionExpired(const StorageException('x', statusCode: '401'));
      expectSessionExpired(const StorageException('exp claim: JWT expired'));
    });

    test('dispara o sinal global uma vez por erro mapeado', () async {
      mapper.map(const AuthException('x', statusCode: '401'));
      await pump();
      expect(notifications, 1);
    });
  });

  group('nao e sessao expirada', () {
    test(
      'senha errada continua sendo invalidCredentials e nao dispara',
      () async {
        final failure = mapper.map(
          const AuthException(
            'x',
            statusCode: '400',
            code: 'invalid_credentials',
          ),
        );
        await pump();
        expect(
          (failure as AuthFailure).reason,
          AuthFailureReason.invalidCredentials,
        );
        expect(notifications, 0);
      },
    );

    test('AuthException sem status nem JWT segue como unknown', () {
      final failure = mapper.map(const AuthException('algo estranho'));
      expect((failure as AuthFailure).reason, AuthFailureReason.unknown);
    });

    test('falha de rede no Auth vira NetworkFailure e nao dispara', () async {
      final failure = mapper.map(AuthRetryableFetchException());
      await pump();
      expect(failure, isA<NetworkFailure>());
      expect(notifications, 0);
    });

    test('Storage 403 (RLS) continua ServerFailure', () async {
      final failure = mapper.map(
        const StorageException(
          'new row violates row-level security',
          statusCode: '403',
        ),
      );
      await pump();
      expect(failure, isA<ServerFailure>());
      expect(notifications, 0);
    });

    test('42501 continua PermissionFailure', () {
      expect(
        mapper.map(const PostgrestException(message: 'x', code: '42501')),
        isA<PermissionFailure>(),
      );
    });

    test('sem sinal injetado nao quebra', () {
      expect(
        () => const SupabaseErrorMapper().map(
          const AuthException('x', statusCode: '401'),
        ),
        returnsNormally,
      );
    });
  });
}
