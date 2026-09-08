import 'dart:convert';
import 'dart:math';

import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/auth/domain/repositories/auth_repository.dart';
import 'package:fifa_queue/features/profile/domain/entities/profile.dart';
import 'package:fifa_queue/features/profile/domain/repositories/profile_repository.dart';
import 'package:fifa_queue/features/teams/domain/entities/team.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_member_status.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_membership.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_role.dart';
import 'package:fifa_queue/features/teams/domain/repositories/team_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalTeamRepository implements TeamRepository {
  LocalTeamRepository(
    this._authRepository,
    this._profileRepository,
    this._preferences,
  );

  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;
  final SharedPreferences _preferences;

  static const String _storageKey = 'teams.local.records';
  static const int _defaultDurationSeconds = 180;

  final Random _random = Random();

  @override
  Future<List<UserTeam>> fetchMyTeams() async {
    final userId = _requireUserId();
    final records =
        _readRecords().where((record) => record.ownerId == userId).toList()
          ..sort((a, b) => a.team.createdAt.compareTo(b.team.createdAt));
    return records
        .map(
          (record) => UserTeam(
            team: record.team,
            role: TeamRole.owner,
            joinedAt: record.team.createdAt,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<Team> createTeam({
    required String name,
    String? tag,
    Duration? defaultSearchDuration,
  }) async {
    final userId = _requireUserId();
    final now = DateTime.now().toUtc();
    final team = Team(
      id: _uuidV4(),
      name: name,
      tag: tag,
      defaultSearchDuration:
          defaultSearchDuration ??
          const Duration(seconds: _defaultDurationSeconds),
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
    final records = _readRecords()
      ..add(_LocalTeamRecord(team: team, ownerId: userId));
    await _writeRecords(records);
    return team;
  }

  @override
  Future<Team> updateTeam({
    required String teamId,
    String? name,
    String? tag,
    bool clearTag = false,
    Duration? defaultSearchDuration,
  }) async {
    final userId = _requireUserId();
    final records = _readRecords();
    final index = records.indexWhere((record) => record.team.id == teamId);
    if (index < 0) {
      throw const TeamFailure(reason: TeamFailureReason.notFound);
    }
    if (records[index].ownerId != userId) {
      throw const TeamFailure(reason: TeamFailureReason.permissionDenied);
    }
    final current = records[index].team;
    final updated = current.copyWith(
      name: name,
      tag: tag,
      clearTag: clearTag,
      defaultSearchDuration: defaultSearchDuration,
      updatedAt: DateTime.now().toUtc(),
    );
    records[index] = _LocalTeamRecord(team: updated, ownerId: userId);
    await _writeRecords(records);
    return updated;
  }

  @override
  Future<Team> updateSearchDuration({
    required String teamId,
    required Duration duration,
  }) => updateTeam(teamId: teamId, defaultSearchDuration: duration);

  /// Sem backend real so existe o proprio usuario -- nunca OFFLINE de
  /// mentirinha pros outros, so a linha do dono, honesta sobre o que a
  /// fila local sabe (nada de IN_MATCH/SEARCHING/QUEUED sem RPC real).
  @override
  Future<List<TeamMemberStatus>> fetchPlayerStatuses(String teamId) async {
    final userId = _requireUserId();
    final profile =
        await _profileRepository.fetchMyProfile() ?? _fallbackProfile(userId);
    return <TeamMemberStatus>[
      TeamMemberStatus(
        userId: userId,
        displayName: profile.displayName,
        avatarUrl: profile.avatarUrl,
        role: TeamRole.owner,
        status: PlayerOperationalStatus.offline,
      ),
    ];
  }

  @override
  Future<List<TeamMember>> fetchMembers(String teamId) async {
    final userId = _requireUserId();
    final matches = _readRecords().where((r) => r.team.id == teamId).toList();
    final record = matches.isEmpty ? null : matches.first;
    if (record == null || record.ownerId != userId) {
      return const <TeamMember>[];
    }
    final profile =
        await _profileRepository.fetchMyProfile() ?? _fallbackProfile(userId);
    return <TeamMember>[
      TeamMember(
        membership: TeamMembership(
          teamId: teamId,
          userId: userId,
          role: TeamRole.owner,
          joinedAt: record.team.createdAt,
        ),
        profile: profile,
      ),
    ];
  }

  Profile _fallbackProfile(String userId) {
    final now = DateTime.now().toUtc();
    return Profile(
      id: userId,
      displayName: _authRepository.currentUser?.shortName ?? 'Jogador',
      createdAt: now,
      updatedAt: now,
    );
  }

  List<_LocalTeamRecord> _readRecords() {
    final raw = _preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return <_LocalTeamRecord>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <_LocalTeamRecord>[];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_LocalTeamRecord.fromJson)
          .toList();
    } on FormatException {
      return <_LocalTeamRecord>[];
    }
  }

  Future<void> _writeRecords(List<_LocalTeamRecord> records) async {
    final encoded = jsonEncode(
      records.map((record) => record.toJson()).toList(),
    );
    await _preferences.setString(_storageKey, encoded);
  }

  String _requireUserId() {
    final user = _authRepository.currentUser;
    if (user == null) {
      throw const AuthFailure(reason: AuthFailureReason.sessionExpired);
    }
    return user.id;
  }

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

class _LocalTeamRecord {
  const _LocalTeamRecord({required this.team, required this.ownerId});

  final Team team;
  final String ownerId;

  factory _LocalTeamRecord.fromJson(Map<String, dynamic> json) {
    final createdAt =
        DateTime.tryParse('${json['created_at']}')?.toUtc() ??
        DateTime.now().toUtc();
    return _LocalTeamRecord(
      ownerId: '${json['owner_id']}',
      team: Team(
        id: '${json['id']}',
        name: '${json['name']}',
        tag: json['tag'] as String?,
        logoUrl: json['logo_url'] as String?,
        primaryColor: json['primary_color'] as String?,
        secondaryColor: json['secondary_color'] as String?,
        defaultSearchDuration: Duration(
          seconds: json['default_search_duration_seconds'] is int
              ? json['default_search_duration_seconds'] as int
              : 180,
        ),
        isActive: json['is_active'] is bool ? json['is_active'] as bool : true,
        createdAt: createdAt,
        updatedAt:
            DateTime.tryParse('${json['updated_at']}')?.toUtc() ?? createdAt,
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': team.id,
    'owner_id': ownerId,
    'name': team.name,
    'tag': team.tag,
    'logo_url': team.logoUrl,
    'primary_color': team.primaryColor,
    'secondary_color': team.secondaryColor,
    'default_search_duration_seconds': team.defaultSearchDuration.inSeconds,
    'is_active': team.isActive,
    'created_at': team.createdAt.toIso8601String(),
    'updated_at': team.updatedAt.toIso8601String(),
  };
}
