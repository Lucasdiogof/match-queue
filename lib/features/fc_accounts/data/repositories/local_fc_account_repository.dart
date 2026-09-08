import 'dart:convert';
import 'dart:math';

import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/auth/domain/repositories/auth_repository.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account_stats.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/rivals_division.dart';
import 'package:fifa_queue/features/fc_accounts/domain/repositories/fc_account_repository.dart';
import 'package:fifa_queue/features/game/domain/entities/player_leaderboard_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sem backend real, elencos locais são só do próprio usuário do
/// aparelho -- vários elencos funcionam (item 55), mas nunca dados de
/// outros usuários, times vinculados ou record de WL (que depende de
/// game_matches reais, que o modo local nunca tem).
class LocalFcAccountRepository implements FcAccountRepository {
  LocalFcAccountRepository(this._authRepository, this._preferences);

  final AuthRepository _authRepository;
  final SharedPreferences _preferences;

  static const String _storageKeyPrefix = 'fc_accounts.local.';
  final Random _random = Random();

  @override
  Future<FcAccountsSnapshot> fetchMyAccounts() async =>
      FcAccountsSnapshot(accounts: _readAccounts());

  @override
  Future<void> createAccount(String name) async {
    final accounts = _readAccounts()
      ..add(
        FcAccount(
          id: _uuidV4(),
          name: name.trim(),
          isActive: true,
          teamIds: const <String>[],
        ),
      );
    await _writeAccounts(accounts);
  }

  @override
  Future<void> updateAccount({required String id, required String name}) async {
    final accounts = _readAccounts();
    final index = accounts.indexWhere((account) => account.id == id);
    if (index < 0) {
      throw const NotFoundFailure();
    }
    accounts[index] = _copyWith(accounts[index], name: name.trim());
    await _writeAccounts(accounts);
  }

  @override
  Future<void> archiveAccount(String id) async {
    final accounts = _readAccounts();
    final index = accounts.indexWhere((account) => account.id == id);
    if (index < 0) {
      return;
    }
    accounts[index] = _copyWith(accounts[index], isActive: false);
    await _writeAccounts(accounts);
  }

  @override
  Future<void> updateRivalsDivision({
    required String id,
    RivalsDivision? division,
  }) async {
    final accounts = _readAccounts();
    final index = accounts.indexWhere((account) => account.id == id);
    if (index < 0) {
      return;
    }
    accounts[index] = _copyWith(accounts[index], rivalsDivision: division);
    await _writeAccounts(accounts);
  }

  @override
  Future<void> linkToTeam({
    required String accountId,
    required String teamId,
  }) async {
    final accounts = _readAccounts();
    final index = accounts.indexWhere((account) => account.id == accountId);
    if (index < 0) {
      return;
    }
    final current = accounts[index];
    if (current.teamIds.contains(teamId)) {
      return;
    }
    accounts[index] = _copyWith(
      current,
      teamIds: <String>[...current.teamIds, teamId],
    );
    await _writeAccounts(accounts);
  }

  @override
  Future<void> unlinkFromTeam({
    required String accountId,
    required String teamId,
  }) async {
    final accounts = _readAccounts();
    final index = accounts.indexWhere((account) => account.id == accountId);
    if (index < 0) {
      return;
    }
    final current = accounts[index];
    accounts[index] = _copyWith(
      current,
      teamIds: current.teamIds.where((id) => id != teamId).toList(),
    );
    await _writeAccounts(accounts);
  }

  @override
  Future<void> setWeekendLeagueManualRecord({
    required String accountId,
    required String eventId,
    required int wins,
    required int losses,
  }) async {}

  @override
  Future<void> clearWeekendLeagueManualRecord({
    required String accountId,
    required String eventId,
  }) async {}

  @override
  Future<FcAccountStats> fetchAccountStats(String accountId) async =>
      FcAccountStats.empty;

  @override
  Future<WeekendLeagueAccountStats> fetchWeekendLeagueAccountStats({
    required String accountId,
    required String eventId,
  }) async => const WeekendLeagueAccountStats(
    computed: FcAccountStats.empty,
    topScorers: <PlayerLeaderboardEntry>[],
    topAssists: <PlayerLeaderboardEntry>[],
  );

  @override
  Future<RivalsAccountStats> fetchRivalsAccountStats(String accountId) async =>
      const RivalsAccountStats(
        aggregate: FcAccountStats.empty,
        topScorers: <PlayerLeaderboardEntry>[],
        topAssists: <PlayerLeaderboardEntry>[],
      );

  FcAccount _copyWith(
    FcAccount account, {
    String? name,
    bool? isActive,
    List<String>? teamIds,
    RivalsDivision? rivalsDivision,
    bool clearRivalsDivision = false,
  }) => FcAccount(
    id: account.id,
    name: name ?? account.name,
    isActive: isActive ?? account.isActive,
    teamIds: teamIds ?? account.teamIds,
    rivalsDivision: clearRivalsDivision
        ? null
        : (rivalsDivision ?? account.rivalsDivision),
  );

  List<FcAccount> _readAccounts() {
    final userId = _authRepository.currentUser?.id;
    if (userId == null) {
      return <FcAccount>[];
    }
    final raw = _preferences.getString('$_storageKeyPrefix$userId');
    if (raw == null || raw.isEmpty) {
      return <FcAccount>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <FcAccount>[];
      }
      return decoded.whereType<Map<String, dynamic>>().map(_fromJson).toList();
    } on FormatException {
      return <FcAccount>[];
    }
  }

  Future<void> _writeAccounts(List<FcAccount> accounts) async {
    final userId = _authRepository.currentUser?.id;
    if (userId == null) {
      return;
    }
    final encoded = jsonEncode(accounts.map(_toJson).toList());
    await _preferences.setString('$_storageKeyPrefix$userId', encoded);
  }

  FcAccount _fromJson(Map<String, dynamic> json) => FcAccount(
    id: '${json['id']}',
    name: '${json['name']}',
    isActive: json['is_active'] as bool? ?? true,
    teamIds: (json['team_ids'] as List<dynamic>? ?? const <dynamic>[])
        .map((id) => '$id')
        .toList(),
    rivalsDivision: RivalsDivision.tryFromKey(json['rivals_division']),
  );

  Map<String, dynamic> _toJson(FcAccount account) => <String, dynamic>{
    'id': account.id,
    'name': account.name,
    'is_active': account.isActive,
    'team_ids': account.teamIds,
    'rivals_division': account.rivalsDivision?.key,
  };

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
