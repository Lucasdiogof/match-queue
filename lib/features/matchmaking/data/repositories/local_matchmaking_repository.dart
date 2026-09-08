import 'dart:convert';
import 'dart:math';

import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/auth/domain/repositories/auth_repository.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/matchmaking_realtime_event.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/my_matchmaking_status.dart';
import 'package:fifa_queue/features/matchmaking/domain/repositories/matchmaking_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sem backend real nao ha uma segunda pessoa pra ocupar a fila -- so o
/// usuario local existe. Por isso este repositorio so simula honestamente o
/// que uma unica pessoa pode fazer sozinha: comecar a buscar, cancelar ou
/// declarar partida encontrada. A fila fica sempre vazia e nunca ha quem
/// bloqueie, mesmo raciocinio de LocalInviteRepository. Chaveado por
/// fcAccountId (Etapa 11) -- este modo nunca teve conceito real de "time
/// vinculado", entao a duracao usa um default fixo em vez de consultar time.
class LocalMatchmakingRepository implements MatchmakingRepository {
  LocalMatchmakingRepository(this._authRepository, this._preferences);

  final AuthRepository _authRepository;
  final SharedPreferences _preferences;

  static const String _storageKeyPrefix = 'matchmaking.local.account.';
  static const Duration _defaultDuration = Duration(seconds: 180);
  final Random _random = Random();

  /// Sem backend nao ha um segundo dispositivo pra gerar evento nenhum.
  /// Em vez de fingir um canal vivo, o stream so anuncia que esta "no ar"
  /// uma vez e nunca mais emite -- e a verdade do modo local.
  @override
  Stream<MatchmakingRealtimeEvent> watchTeam(String teamId) =>
      Stream<MatchmakingRealtimeEvent>.value(const MatchmakingSubscribed());

  @override
  Future<MyMatchmakingSnapshot> getMyStatus(String fcAccountId) async =>
      _buildSnapshot(fcAccountId);

  @override
  Future<MyMatchmakingSnapshot> requestSearch({
    required String fcAccountId,
    String? fcSquadId,
    required GameMode mode,
  }) async {
    final existing = _readSession(fcAccountId);
    if (existing != null && existing.expiresAt.isAfter(DateTime.now())) {
      return _buildSnapshot(fcAccountId);
    }
    final now = DateTime.now();
    await _writeSession(
      fcAccountId,
      _LocalSession(
        sessionId: _uuidV4(),
        startedAt: now,
        expiresAt: now.add(_defaultDuration),
        gameMode: mode.key,
        fcSquadId: fcSquadId,
      ),
    );
    return _buildSnapshot(fcAccountId);
  }

  @override
  Future<MyMatchmakingSnapshot> cancelSearch(String fcAccountId) async {
    final existing = _readSession(fcAccountId);
    if (existing == null) {
      throw const MatchmakingFailure(
        reason: MatchmakingFailureReason.noActiveSearch,
      );
    }
    await _clearSession(fcAccountId);
    return _buildSnapshot(fcAccountId);
  }

  @override
  Future<MyMatchmakingSnapshot> reportMatchFound(String fcAccountId) async {
    final existing = _readSession(fcAccountId);
    if (existing == null) {
      throw const MatchmakingFailure(
        reason: MatchmakingFailureReason.noActiveSearch,
      );
    }
    await _clearSession(fcAccountId);
    return _buildSnapshot(fcAccountId);
  }

  Future<MyMatchmakingSnapshot> _buildSnapshot(String fcAccountId) async {
    _requireUserId();
    final session = _readSession(fcAccountId);
    final isExpired =
        session != null && !session.expiresAt.isAfter(DateTime.now());
    if (isExpired) {
      await _clearSession(fcAccountId);
    }
    final active = isExpired ? null : session;
    return MyMatchmakingSnapshot(
      fcAccountId: fcAccountId,
      linkedTeamIds: const <String>[],
      searchDurationSeconds: _defaultDuration.inSeconds,
      searching: active == null
          ? null
          : MySearching(
              sessionId: active.sessionId,
              startedAt: active.startedAt,
              expiresAt: active.expiresAt,
              gameMode: GameMode.tryFromKey(active.gameMode),
              fcSquadId: active.fcSquadId,
            ),
      myStatus: active == null
          ? MyMatchmakingStatus.none
          : MyMatchmakingStatus.searching,
      serverNow: DateTime.now(),
    );
  }

  String _requireUserId() {
    final user = _authRepository.currentUser;
    if (user == null) {
      throw const AuthFailure(reason: AuthFailureReason.sessionExpired);
    }
    return user.id;
  }

  _LocalSession? _readSession(String fcAccountId) {
    final raw = _preferences.getString('$_storageKeyPrefix$fcAccountId');
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

  Future<void> _writeSession(String fcAccountId, _LocalSession session) =>
      _preferences.setString(
        '$_storageKeyPrefix$fcAccountId',
        jsonEncode(session.toJson()),
      );

  Future<void> _clearSession(String fcAccountId) =>
      _preferences.remove('$_storageKeyPrefix$fcAccountId');

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
    this.fcSquadId,
  });

  final String sessionId;
  final DateTime startedAt;
  final DateTime expiresAt;
  final String? gameMode;
  final String? fcSquadId;

  factory _LocalSession.fromJson(Map<String, dynamic> json) => _LocalSession(
    sessionId: '${json['session_id']}',
    startedAt: DateTime.parse('${json['started_at']}'),
    expiresAt: DateTime.parse('${json['expires_at']}'),
    gameMode: json['game_mode'] as String?,
    fcSquadId: json['fc_squad_id'] as String?,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'session_id': sessionId,
    'started_at': startedAt.toIso8601String(),
    'expires_at': expiresAt.toIso8601String(),
    'game_mode': gameMode,
    'fc_squad_id': fcSquadId,
  };
}
