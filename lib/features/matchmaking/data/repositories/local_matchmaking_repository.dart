import 'dart:convert';
import 'dart:math';

import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/auth/domain/repositories/auth_repository.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/matchmaking_realtime_event.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/matchmaking_snapshot.dart';
import 'package:fifa_queue/features/matchmaking/domain/repositories/matchmaking_repository.dart';
import 'package:fifa_queue/features/teams/domain/repositories/team_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sem backend real nao ha uma segunda pessoa pra ocupar a fila -- so o
/// usuario local existe. Por isso este repositorio so simula honestamente o
/// que uma unica pessoa pode fazer sozinha: comecar a buscar, cancelar ou
/// declarar partida encontrada. A fila fica sempre vazia, nunca uma
/// simulacao fake de outros jogadores que o storage local nao tem como
/// sustentar (mesmo raciocinio de LocalInviteRepository).
class LocalMatchmakingRepository implements MatchmakingRepository {
  LocalMatchmakingRepository(
    this._authRepository,
    this._teamRepository,
    this._preferences,
  );

  final AuthRepository _authRepository;
  final TeamRepository _teamRepository;
  final SharedPreferences _preferences;

  static const String _storageKeyPrefix = 'matchmaking.local.session.';
  final Random _random = Random();

  /// Sem backend nao ha um segundo dispositivo pra gerar evento nenhum.
  /// Em vez de fingir um canal vivo (ou de deixar a UI achando que caiu a
  /// conexao), o stream so anuncia que esta "no ar" uma vez e nunca mais
  /// emite -- e a verdade do modo local.
  @override
  Stream<MatchmakingRealtimeEvent> watchTeam(String teamId) =>
      Stream<MatchmakingRealtimeEvent>.value(const MatchmakingSubscribed());

  @override
  Future<MatchmakingSnapshot> getState(String teamId) async =>
      _buildSnapshot(teamId);

  @override
  Future<MatchmakingSnapshot> requestSearch(
    String teamId, {
    required String fcAccountId,
    String? fcSquadId,
    required GameMode mode,
  }) async {
    final existing = _readSession(teamId);
    if (existing != null && existing.expiresAt.isAfter(DateTime.now())) {
      return _buildSnapshot(teamId);
    }
    final duration = await _searchDuration(teamId);
    final now = DateTime.now();
    await _writeSession(
      teamId,
      _LocalSession(
        sessionId: _uuidV4(),
        startedAt: now,
        expiresAt: now.add(duration),
        gameMode: mode.key,
      ),
    );
    return _buildSnapshot(teamId);
  }

  @override
  Future<MatchmakingSnapshot> cancelSearch(String teamId) async {
    final existing = _readSession(teamId);
    if (existing == null) {
      throw const MatchmakingFailure(
        reason: MatchmakingFailureReason.noActiveSearch,
      );
    }
    await _clearSession(teamId);
    return _buildSnapshot(teamId);
  }

  @override
  Future<MatchmakingSnapshot> reportMatchFound(String teamId) async {
    final existing = _readSession(teamId);
    if (existing == null) {
      throw const MatchmakingFailure(
        reason: MatchmakingFailureReason.noActiveSearch,
      );
    }
    await _clearSession(teamId);
    return _buildSnapshot(teamId);
  }

  Future<MatchmakingSnapshot> _buildSnapshot(String teamId) async {
    final duration = await _searchDuration(teamId);
    final userId = _requireUserId();
    final session = _readSession(teamId);
    final isExpired =
        session != null && !session.expiresAt.isAfter(DateTime.now());
    if (isExpired) {
      await _clearSession(teamId);
    }
    final active = isExpired ? null : session;
    return MatchmakingSnapshot(
      teamId: teamId,
      searchDurationSeconds: duration.inSeconds,
      searching: active == null
          ? null
          : SearchingPlayer(
              sessionId: active.sessionId,
              userId: userId,
              displayName: _authRepository.currentUser?.shortName ?? 'Você',
              startedAt: active.startedAt,
              expiresAt: active.expiresAt,
              gameMode: GameMode.tryFromKey(active.gameMode),
            ),
      queue: const <MatchmakingQueueEntry>[],
      myStatus: active == null
          ? MyMatchmakingStatus.none
          : MyMatchmakingStatus.searching,
      serverNow: DateTime.now(),
    );
  }

  Future<Duration> _searchDuration(String teamId) async {
    final teams = await _teamRepository.fetchMyTeams();
    for (final userTeam in teams) {
      if (userTeam.team.id == teamId) {
        return userTeam.team.defaultSearchDuration;
      }
    }
    return const Duration(seconds: 180);
  }

  String _requireUserId() {
    final user = _authRepository.currentUser;
    if (user == null) {
      throw const AuthFailure(reason: AuthFailureReason.sessionExpired);
    }
    return user.id;
  }

  _LocalSession? _readSession(String teamId) {
    final raw = _preferences.getString('$_storageKeyPrefix$teamId');
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return _LocalSession.fromJson(decoded);
    } on FormatException {
      return null;
    }
  }

  Future<void> _writeSession(String teamId, _LocalSession session) =>
      _preferences.setString(
        '$_storageKeyPrefix$teamId',
        jsonEncode(session.toJson()),
      );

  Future<void> _clearSession(String teamId) =>
      _preferences.remove('$_storageKeyPrefix$teamId');

  String _uuidV4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}

class _LocalSession {
  const _LocalSession({
    required this.sessionId,
    required this.startedAt,
    required this.expiresAt,
    this.gameMode,
  });

  final String sessionId;
  final DateTime startedAt;
  final DateTime expiresAt;
  final String? gameMode;

  factory _LocalSession.fromJson(Map<String, dynamic> json) => _LocalSession(
    sessionId: '${json['session_id']}',
    startedAt: DateTime.parse('${json['started_at']}'),
    expiresAt: DateTime.parse('${json['expires_at']}'),
    gameMode: json['game_mode'] as String?,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'session_id': sessionId,
    'started_at': startedAt.toIso8601String(),
    'expires_at': expiresAt.toIso8601String(),
    'game_mode': gameMode,
  };
}
