import 'dart:convert';
import 'dart:math';

import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/invitations/domain/entities/invite_preview.dart';
import 'package:fifa_queue/features/invitations/domain/entities/join_team_result.dart';
import 'package:fifa_queue/features/invitations/domain/entities/team_invite.dart';
import 'package:fifa_queue/features/invitations/domain/repositories/invite_repository.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_membership.dart';
import 'package:fifa_queue/features/teams/domain/repositories/team_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sem backend real nao ha como simular uma SEGUNDA pessoa entrando num
/// time -- localmente so existe o usuario local e os times que ele mesmo
/// "possui" (ver LocalTeamRepository). Por isso resolve/join aqui sempre
/// resolvem dentro dos proprios times locais e devolvem already_member:
/// e o comportamento honesto para esse modo, nao uma simulacao de
/// multiplayer que o storage local nao suporta.
class LocalInviteRepository implements InviteRepository {
  LocalInviteRepository(this._teamRepository, this._preferences);

  final TeamRepository _teamRepository;
  final SharedPreferences _preferences;

  static const String _storageKey = 'invitations.local.records';
  static const int _codeLength = 12;
  static const String _alphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

  final Random _random = Random.secure();

  @override
  Future<InvitePreview> resolveInvite(String code) async {
    final record = _findByCode(code);
    if (record == null) {
      return const InvitePreview(status: InviteStatus.invalid);
    }
    if (!record.isActive) {
      return const InvitePreview(status: InviteStatus.revoked);
    }
    final userTeam = await _findUserTeam(record.teamId);
    if (userTeam == null) {
      return const InvitePreview(status: InviteStatus.invalid);
    }
    return InvitePreview(
      status: InviteStatus.alreadyMember,
      teamId: userTeam.team.id,
      teamName: userTeam.team.name,
      teamTag: userTeam.team.tag,
      teamLogoUrl: userTeam.team.logoUrl,
      memberCount: 1,
      isAlreadyMember: true,
    );
  }

  @override
  Future<JoinTeamResult> joinTeam(String code) async {
    final record = _findByCode(code);
    if (record == null) {
      throw const InviteFailure(reason: InviteFailureReason.notFound);
    }
    if (!record.isActive) {
      throw const InviteFailure(reason: InviteFailureReason.notActive);
    }
    final userTeam = await _findUserTeam(record.teamId);
    if (userTeam == null) {
      throw const InviteFailure(reason: InviteFailureReason.notFound);
    }
    return JoinTeamResult(
      alreadyMember: true,
      teamId: userTeam.team.id,
      teamName: userTeam.team.name,
      teamTag: userTeam.team.tag,
      role: userTeam.role.key,
    );
  }

  @override
  Future<TeamInvite> getOrCreateActiveInvite(String teamId) async {
    final records = _readRecords();
    final active = records.where(
      (record) => record.teamId == teamId && record.isActive,
    );
    if (active.isNotEmpty) {
      return active.first.toEntity();
    }
    final created = _LocalInviteRecord(
      id: _uuidV4(),
      teamId: teamId,
      code: _generateUniqueCode(records),
      isActive: true,
      usageCount: 0,
      createdAt: DateTime.now().toUtc(),
    );
    records.add(created);
    await _writeRecords(records);
    return created.toEntity();
  }

  @override
  Future<TeamInvite> rotateInvite(String teamId) async {
    final records = _deactivateAll(teamId);
    final created = _LocalInviteRecord(
      id: _uuidV4(),
      teamId: teamId,
      code: _generateUniqueCode(records),
      isActive: true,
      usageCount: 0,
      createdAt: DateTime.now().toUtc(),
    );
    records.add(created);
    await _writeRecords(records);
    return created.toEntity();
  }

  @override
  Future<void> revokeInvite(String teamId) async {
    await _writeRecords(_deactivateAll(teamId));
  }

  List<_LocalInviteRecord> _deactivateAll(String teamId) {
    final now = DateTime.now().toUtc();
    return _readRecords()
        .map(
          (record) => record.teamId == teamId && record.isActive
              ? record.copyWith(isActive: false, revokedAt: now)
              : record,
        )
        .toList();
  }

  _LocalInviteRecord? _findByCode(String code) {
    for (final record in _readRecords()) {
      if (record.code == code) {
        return record;
      }
    }
    return null;
  }

  Future<UserTeam?> _findUserTeam(String teamId) async {
    final teams = await _teamRepository.fetchMyTeams();
    for (final userTeam in teams) {
      if (userTeam.team.id == teamId) {
        return userTeam;
      }
    }
    return null;
  }

  String _generateUniqueCode(List<_LocalInviteRecord> existing) {
    final usedCodes = existing.map((record) => record.code).toSet();
    while (true) {
      final code = String.fromCharCodes(
        List<int>.generate(
          _codeLength,
          (_) => _alphabet.codeUnitAt(_random.nextInt(_alphabet.length)),
        ),
      );
      if (!usedCodes.contains(code)) {
        return code;
      }
    }
  }

  List<_LocalInviteRecord> _readRecords() {
    final raw = _preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return <_LocalInviteRecord>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <_LocalInviteRecord>[];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_LocalInviteRecord.fromJson)
          .toList();
    } on FormatException {
      return <_LocalInviteRecord>[];
    }
  }

  Future<void> _writeRecords(List<_LocalInviteRecord> records) async {
    final encoded = jsonEncode(
      records.map((record) => record.toJson()).toList(),
    );
    await _preferences.setString(_storageKey, encoded);
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

class _LocalInviteRecord {
  const _LocalInviteRecord({
    required this.id,
    required this.teamId,
    required this.code,
    required this.isActive,
    required this.usageCount,
    required this.createdAt,
    this.revokedAt,
  });

  final String id;
  final String teamId;
  final String code;
  final bool isActive;
  final int usageCount;
  final DateTime createdAt;
  final DateTime? revokedAt;

  _LocalInviteRecord copyWith({bool? isActive, DateTime? revokedAt}) =>
      _LocalInviteRecord(
        id: id,
        teamId: teamId,
        code: code,
        isActive: isActive ?? this.isActive,
        usageCount: usageCount,
        createdAt: createdAt,
        revokedAt: revokedAt ?? this.revokedAt,
      );

  TeamInvite toEntity() => TeamInvite(
    id: id,
    teamId: teamId,
    code: code,
    isActive: isActive,
    usageCount: usageCount,
    createdAt: createdAt,
    revokedAt: revokedAt,
  );

  factory _LocalInviteRecord.fromJson(Map<String, dynamic> json) =>
      _LocalInviteRecord(
        id: '${json['id']}',
        teamId: '${json['team_id']}',
        code: '${json['code']}',
        isActive: json['is_active'] == true,
        usageCount: json['usage_count'] is int ? json['usage_count'] as int : 0,
        createdAt:
            DateTime.tryParse('${json['created_at']}')?.toUtc() ??
            DateTime.now().toUtc(),
        revokedAt: json['revoked_at'] is String
            ? DateTime.tryParse(json['revoked_at'] as String)?.toUtc()
            : null,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'team_id': teamId,
    'code': code,
    'is_active': isActive,
    'usage_count': usageCount,
    'created_at': createdAt.toIso8601String(),
    'revoked_at': revokedAt?.toIso8601String(),
  };
}
