import 'dart:async';

import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/supabase/session_expired_signal.dart';
import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseErrorMapper {
  const SupabaseErrorMapper({SessionExpiredSignal? sessionExpiredSignal})
    : _sessionExpiredSignal = sessionExpiredSignal;

  final SessionExpiredSignal? _sessionExpiredSignal;

  AppFailure map(Object error) {
    final failure = _map(error);
    if (failure is AuthFailure &&
        failure.reason == AuthFailureReason.sessionExpired) {
      _sessionExpiredSignal?.notify();
    }
    return failure;
  }

  AppFailure _map(Object error) {
    if (error is AppFailure) {
      return error;
    }
    if (error is AuthRetryableFetchException) {
      // Falha de rede ao falar com o Auth (ex.: refresh sem internet) -- o
      // token pode estar perfeito, entao nao e motivo pra deslogar.
      return NetworkFailure(debugMessage: error.message);
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
      if (error.statusCode == '401' || _looksLikeExpiredToken(error.message)) {
        return AuthFailure(
          reason: AuthFailureReason.sessionExpired,
          debugMessage: error.message,
        );
      }
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

  bool _looksLikeExpiredToken(String message) {
    final lower = message.toLowerCase();
    return lower.contains('jwt') || lower.contains('refresh token');
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
    'FQ006' => TeamFailureReason.accountMissing,
    'FQ007' => TeamFailureReason.invalidSearchDuration,
    'FQ044' => TeamFailureReason.soleOwnerBlocksAccountDeletion,
    'FQ053' || 'FQ057' => TeamFailureReason.notFound,
    'FQ054' => TeamFailureReason.alreadyMember,
    'FQ055' => TeamFailureReason.duplicateRequest,
    'FQ056' => TeamFailureReason.requestNotFound,
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
    // Colisao persistente ao sortear codigo novo. Com 60 bits de entropia
    // isso e praticamente inalcancavel, mas quando acontece a saida certa e
    // pedir pra tentar de novo, nao mostrar erro generico.
    'FQ013' => InviteFailureReason.generationFailed,
    _ => null,
  };

  // FQ012 (nao e membro do time) nao aparece aqui: as RPCs de matchmaking
  // so sao chamadas pela UI para o SelectedTeam, do qual o usuario sempre e
  // membro, entao esse caminho e inalcancavel na pratica -- e _inviteReasonFrom
  // (checado antes deste) ja o classifica como InviteFailure(permissionDenied),
  // uma classificacao razoavel mesmo que o texto nao seja especifico de fila.
  MatchmakingFailureReason? _matchmakingReasonFrom(String? code) =>
      switch (code) {
        'FQ015' => MatchmakingFailureReason.noActiveSearch,
        'FQ016' => MatchmakingFailureReason.notCurrentSearcher,
        'FQ017' => MatchmakingFailureReason.alreadyInOtherState,
        'FQ018' => MatchmakingFailureReason.teamInactive,
        'FQ047' => MatchmakingFailureReason.notInQueue,
        _ => null,
      };

  GameFailureReason? _gameReasonFrom(String? code) => switch (code) {
    'FQ020' => GameFailureReason.cooldown,
    'FQ021' => GameFailureReason.matchNotFound,
    'FQ022' => GameFailureReason.matchAlreadyFinished,
    'FQ023' => GameFailureReason.invalidMode,
    'FQ024' => GameFailureReason.invalidResult,
    'FQ036' => GameFailureReason.invalidStatsPayload,
    'FQ037' => GameFailureReason.playerNotInSquad,
    'FQ038' => GameFailureReason.noSquadSnapshot,
    'FQ039' => GameFailureReason.matchNotFinished,
    'FQ046' => GameFailureReason.weekendLeagueLimit,
    _ => null,
  };

  AccountFailureReason? _accountReasonFrom(String? code) => switch (code) {
    'FQ058' => AccountFailureReason.platformRequired,
    _ => null,
  };

  SquadFailureReason? _squadReasonFrom(String? code) => switch (code) {
    'FQ029' => SquadFailureReason.notFound,
    'FQ030' => SquadFailureReason.invalidName,
    'FQ031' => SquadFailureReason.invalidFormation,
    'FQ032' => SquadFailureReason.invalidSlot,
    'FQ033' => SquadFailureReason.cardCannotPlayPosition,
    'FQ034' => SquadFailureReason.inUseByActiveSearch,
    'FQ049' => SquadFailureReason.editConflict,
    'FQ050' => SquadFailureReason.invalidLineup,
    'FQ051' => SquadFailureReason.duplicatedPlayer,
    'FQ052' => SquadFailureReason.cardCannotPlayPosition,
    _ => null,
  };

  PublicProfileFailureReason? _publicProfileReasonFrom(String? code) =>
      switch (code) {
        'FQ040' => PublicProfileFailureReason.invalidSlugFormat,
        'FQ041' => PublicProfileFailureReason.reservedSlug,
        'FQ042' => PublicProfileFailureReason.slugTaken,
        'FQ043' => PublicProfileFailureReason.slugRequired,
        _ => null,
      };

  AuthFailureReason _authReasonFrom(AuthException error) {
    if (error is AuthSessionMissingException) {
      return AuthFailureReason.sessionExpired;
    }
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
        // Sem codigo conhecido: 401/403 ou token invalido na mensagem
        // continua sendo sessao que nao vale mais, nao "erro desconhecido".
        if (error.statusCode == '401' ||
            error.statusCode == '403' ||
            _looksLikeExpiredToken(error.message)) {
          return AuthFailureReason.sessionExpired;
        }
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
    final squadReason = _squadReasonFrom(error.code);
    if (squadReason != null) {
      return SquadFailure(reason: squadReason, debugMessage: error.message);
    }
    final matchmakingReason = _matchmakingReasonFrom(error.code);
    if (matchmakingReason != null) {
      return MatchmakingFailure(
        reason: matchmakingReason,
        debugMessage: error.message,
      );
    }
    final gameReason = _gameReasonFrom(error.code);
    if (gameReason != null) {
      return GameFailure(reason: gameReason, debugMessage: error.message);
    }
    final accountReason = _accountReasonFrom(error.code);
    if (accountReason != null) {
      return AccountFailure(reason: accountReason, debugMessage: error.message);
    }
    final publicProfileReason = _publicProfileReasonFrom(error.code);
    if (publicProfileReason != null) {
      return PublicProfileFailure(
        reason: publicProfileReason,
        debugMessage: error.message,
      );
    }
    switch (error.code) {
      case '23505':
        return ConflictFailure(debugMessage: error.message);
      case 'PGRST301':
      case 'PGRST303':
        // JWT expirado / claims invalidas: sessao, nao permissao.
        return AuthFailure(
          reason: AuthFailureReason.sessionExpired,
          debugMessage: error.message,
        );
      case '42501':
        return PermissionFailure(debugMessage: error.message);
      case 'PGRST116':
        return NotFoundFailure(debugMessage: error.message);
      default:
        return ServerFailure(debugMessage: error.message);
    }
  }
}
