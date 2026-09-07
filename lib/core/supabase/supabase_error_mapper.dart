import 'dart:async';

import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseErrorMapper {
  const SupabaseErrorMapper();

  AppFailure map(Object error) {
    if (error is AppFailure) {
      return error;
    }
    if (error is AuthException) {
      return AuthFailure(
        reason: _authReasonFrom(error),
        debugMessage: error.message,
      );
    }
    if (error is PostgrestException) {
      return _fromPostgrest(error);
    }
    if (error is StorageException) {
      return ServerFailure(debugMessage: error.message);
    }
    if (error is ClientException || _looksLikeTransportError(error)) {
      return NetworkFailure(debugMessage: '$error');
    }
    if (error is TimeoutException) {
      return TimeoutFailure(debugMessage: '$error');
    }
    return UnexpectedFailure(debugMessage: '$error');
  }

  bool _looksLikeTransportError(Object error) {
    const transportErrorTypes = <String>{
      'SocketException',
      'HttpException',
      'HandshakeException',
      'ConnectionException',
    };
    return transportErrorTypes.contains(error.runtimeType.toString());
  }

  TeamFailureReason? _teamReasonFrom(String? code) => switch (code) {
    'FQ001' => TeamFailureReason.invalidName,
    'FQ002' => TeamFailureReason.invalidTag,
    'FQ003' => TeamFailureReason.permissionDenied,
    'FQ004' || 'FQ005' => TeamFailureReason.permissionDenied,
    'FQ006' => TeamFailureReason.profileMissing,
    'FQ007' => TeamFailureReason.invalidSearchDuration,
    _ => null,
  };

  // FQ003 (autenticacao ausente) nao aparece aqui de proposito: as RPCs de
  // convite so sao chamadas pela UI quando ja ha sessao, entao esse caso e
  // inalcancavel na pratica -- se algum dia o Postgres devolver FQ003 por um
  // caminho que nao passa pela UI normal, cai em _teamReasonFrom (checado
  // antes deste) e vira TeamFailure(permissionDenied), o que ja e uma
  // classificacao razoavel.
  InviteFailureReason? _inviteReasonFrom(String? code) => switch (code) {
    'FQ012' => InviteFailureReason.permissionDenied,
    'FQ008' => InviteFailureReason.notFound,
    'FQ009' => InviteFailureReason.notActive,
    'FQ010' => InviteFailureReason.expired,
    'FQ011' => InviteFailureReason.exhausted,
    _ => null,
  };

  AuthFailureReason _authReasonFrom(AuthException error) {
    switch (error.code) {
      case 'invalid_credentials':
      case 'invalid_grant':
        return AuthFailureReason.invalidCredentials;
      case 'user_already_exists':
      case 'email_exists':
        return AuthFailureReason.emailAlreadyRegistered;
      case 'weak_password':
        return AuthFailureReason.weakPassword;
      case 'user_not_found':
        return AuthFailureReason.userNotFound;
      case 'session_not_found':
      case 'refresh_token_not_found':
      case 'session_expired':
        return AuthFailureReason.sessionExpired;
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return AuthFailureReason.tooManyRequests;
      default:
        return AuthFailureReason.unknown;
    }
  }

  AppFailure _fromPostgrest(PostgrestException error) {
    final teamReason = _teamReasonFrom(error.code);
    if (teamReason != null) {
      return TeamFailure(reason: teamReason, debugMessage: error.message);
    }
    final inviteReason = _inviteReasonFrom(error.code);
    if (inviteReason != null) {
      return InviteFailure(reason: inviteReason, debugMessage: error.message);
    }
    switch (error.code) {
      case '23505':
        return ConflictFailure(debugMessage: error.message);
      case '42501':
      case 'PGRST301':
        return PermissionFailure(debugMessage: error.message);
      case 'PGRST116':
        return NotFoundFailure(debugMessage: error.message);
      default:
        return ServerFailure(debugMessage: error.message);
    }
  }
}
