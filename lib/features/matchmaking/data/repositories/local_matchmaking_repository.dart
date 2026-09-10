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
/// bloqueie. Chaveado por (fcAccountId, teamId): a fila real por time
/// existe no servidor, entao o modo local so precisa parecer plausivel
/// por time, sem tentar imitar concorrencia entre times.
class LocalMatchmakingRepository implements MatchmakingRepository {
  LocalMatchmakingRepository(this._authRepository, this._preferences);

  final AuthRepository _authRepository;
  final SharedPreferences _preferences;

  static const String _storageKeyPrefix = 'matchmaking.local.';
  static const Duration _defaultDuration = Duration(seconds: 180);
  final Random _random = Random();

  /// Sem backend nao ha um segundo dispositivo pra gerar evento nenhum.
  /// Em vez de fingir um canal vivo, o stream so anuncia que esta "no ar"
  /// uma vez e nunca mais emite -- e a verdade do modo local.
  @override
  Stream<MatchmakingRealtimeEvent> watchTeam(String teamId) =>
      Stream<MatchmakingRealtimeEvent>.value(const MatchmakingSubscribed());

  @override
  Future<MyMatchmakingSnapshot> getMyStatus({
    required String fcAccountId,
    required String teamId,
  }) async => _buildSnapshot(fcAccountId, teamId);

  @override
  Future<MyMatchmakingSnapshot> requestSearch({
    required String fcAccountId,
    required String teamId,
    String? fcSquadId,
    required GameMode mode,
  }) async {
    final key = _key(fcAccountId, teamId);
    final existing = _readSession(key);
    if (existing != null && existing.expiresAt.isAfter(DateTime.now())) {
      return _buildSnapshot(fcAccountId, teamId);
    }
    final now = DateTime.now();
    await _writeSession(
      key,
      _LocalSession(
        sessionId: _uuidV4(),
        startedAt: now,
        expiresAt: now.add(_defaultDuration),
        gameMode: mode.key,
        fcSquadId: fcSquadId,
      ),
    );
    return _buildSnapshot(fcAccountId, teamId);
  }

  @override
  Future<MyMatchmakingSnapshot> cancelSearch(String fcAccountId) async {
    final key = _findActiveKey(fcAccountId);
    if (key == null) {
      throw const MatchmakingFailure(
        reason: MatchmakingFailureReason.noActiveSearch,
      );
    }
    final teamId = _teamIdFromKey(key);
    await _clearSession(key);
    return _buildSnapshot(fcAccountId, teamId);
  }

  @override
  Future<MyMatchmakingSnapshot> leaveQueue({
    required String fcAccountId,
    required String teamId,
  }) async =>
      // Modo local nunca enfileira (sempre livre pra uma unica pessoa).
      _buildSnapshot(fcAccountId, teamId);

  @override
  Future<MyMatchmakingSnapshot> reportMatchFound(String fcAccountId) async {
    final key = _findActiveKey(fcAccountId);
    if (key == null) {
      throw const MatchmakingFailure(
        reason: MatchmakingFailureReason.noActiveSearch,
      );
    }
    final teamId = _teamIdFromKey(key);
    await _clearSession(key);
    return _buildSnapshot(fcAccountId, teamId);
  }

  @override
  Future<void> requestPriority({
    required String fcAccountId,
    required String teamId,
  }) async {
    // Sem outra pessoa buscando no modo local, nunca ha o que priorizar.
  }

  Future<MyMatchmakingSnapshot> _buildSnapshot(
    String fcAccountId,
    String teamId,
  ) async {
    _requireUserId();
    final key = _key(fcAccountId, teamId);
    final session = _readSession(key);
    final isExpired =
        session != null && !session.expiresAt.isAfter(DateTime.now());
    if (isExpired) {
      await _clearSession(key);
    }
    final active = isExpired ? null : session;
    return MyMatchmakingSnapshot(
      fcAccountId: fcAccountId,
      teamId: teamId,
      accountLinkedToTeam: true,
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

  String _key(String fcAccountId, String teamId) =>
      '$_storageKeyPrefix$fcAccountId.$teamId';

  String _teamIdFromKey(String key) => key.substring(key.lastIndexOf('.') + 1);

  /// Modo local nunca busca em mais de um time ao mesmo tempo na pratica,
  /// mas [cancelSearch]/[reportMatchFound] recebem so a conta -- acha a
  /// unica chave ativa dela entre as preferencias salvas.
  String? _findActiveKey(String fcAccountId) {
    final prefix = '$_storageKeyPrefix$fcAccountId.';
    for (final storedKey in _preferences.getKeys()) {
      if (storedKey.startsWith(prefix) && _readSession(storedKey) != null) {
        return storedKey;
      }
    }
    return null;
  }

  _LocalSession? _readSession(String key) {
    final raw = _preferences.getString(key);
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

  Future<void> _writeSession(String key, _LocalSession session) =>
      _preferences.setString(key, jsonEncode(session.toJson()));

  Future<void> _clearSession(String key) => _preferences.remove(key);

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
