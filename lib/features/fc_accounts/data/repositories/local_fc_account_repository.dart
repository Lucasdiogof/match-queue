import 'dart:convert';
import 'dart:math';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/auth/domain/repositories/auth_repository.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account_stats.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/rivals_division.dart';
import 'package:fifa_queue/features/fc_accounts/domain/repositories/fc_account_repository.dart';
import 'package:fifa_queue/features/game/domain/entities/player_leaderboard_entry.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_event.dart';
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
  }) async {
    final accounts = _readAccounts();
    final index = accounts.indexWhere((account) => account.id == accountId);
    if (index < 0) {
      return;
    }
    accounts[index] = _copyWith(
      accounts[index],
      weekendLeagueManualWins: wins,
      weekendLeagueManualLosses: losses,
    );
    await _writeAccounts(accounts);
  }

  @override
  Future<void> clearWeekendLeagueManualRecord({
    required String accountId,
    required String eventId,
  }) async {
    final accounts = _readAccounts();
    final index = accounts.indexWhere((account) => account.id == accountId);
    if (index < 0) {
      return;
    }
    accounts[index] = _copyWith(
      accounts[index],
      clearWeekendLeagueManual: true,
    );
    await _writeAccounts(accounts);
  }

  @override
  Future<void> incrementWeekendLeagueManualRecord({
    required String accountId,
    required String eventId,
    int winDelta = 0,
    int lossDelta = 0,
  }) async {
    final accounts = _readAccounts();
    final index = accounts.indexWhere((account) => account.id == accountId);
    if (index < 0) {
      return;
    }
    final current = accounts[index];
    accounts[index] = _copyWith(
      current,
      weekendLeagueManualWins: max(
        0,
        (current.weekendLeagueManualWins ?? 0) + winDelta,
      ),
      weekendLeagueManualLosses: max(
        0,
        (current.weekendLeagueManualLosses ?? 0) + lossDelta,
      ),
    );
    await _writeAccounts(accounts);
  }

  @override
  Future<void> incrementRivalsManualRecord({
    required String accountId,
    int winDelta = 0,
    int lossDelta = 0,
  }) async {
    final accounts = _readAccounts();
    final index = accounts.indexWhere((account) => account.id == accountId);
    if (index < 0) {
      return;
    }
    final current = accounts[index];
    accounts[index] = _copyWith(
      current,
      rivalsWins: max(0, current.rivalsWins + winDelta),
      rivalsLosses: max(0, current.rivalsLosses + lossDelta),
    );
    await _writeAccounts(accounts);
  }

  @override
  Future<FcAccountStats> fetchAccountStats(String accountId) async =>
      FcAccountStats.empty;

  @override
  Future<List<WeekendLeagueEvent>> fetchWeekendLeagueEvents() async =>
      const <WeekendLeagueEvent>[];

  @override
  Future<WeekendLeagueAccountStats> fetchWeekendLeagueAccountStats({
    required String accountId,
    required String eventId,
  }) async {
    final account = _readAccounts().where((a) => a.id == accountId).firstOrNull;
    return WeekendLeagueAccountStats(
      computed: FcAccountStats.empty,
      manual: account?.hasWeekendLeagueManualOverride ?? false
          ? ManualRecord(
              wins: account!.weekendLeagueManualWins!,
              losses: account.weekendLeagueManualLosses!,
            )
          : null,
      topScorers: const <PlayerLeaderboardEntry>[],
      topAssists: const <PlayerLeaderboardEntry>[],
    );
  }

  @override
  Future<RivalsAccountStats> fetchRivalsAccountStats(String accountId) async {
    final account = _readAccounts().where((a) => a.id == accountId).firstOrNull;
    return RivalsAccountStats(
      aggregate: FcAccountStats.empty,
      manual: ManualRecord(
        wins: account?.rivalsWins ?? 0,
        losses: account?.rivalsLosses ?? 0,
      ),
      topScorers: const <PlayerLeaderboardEntry>[],
      topAssists: const <PlayerLeaderboardEntry>[],
    );
  }

  FcAccount _copyWith(
    FcAccount account, {
    String? name,
    bool? isActive,
    List<String>? teamIds,
    RivalsDivision? rivalsDivision,
    bool clearRivalsDivision = false,
    int? weekendLeagueManualWins,
    int? weekendLeagueManualLosses,
    bool clearWeekendLeagueManual = false,
    int? rivalsWins,
    int? rivalsLosses,
  }) => FcAccount(
    id: account.id,
    name: name ?? account.name,
    isActive: isActive ?? account.isActive,
    teamIds: teamIds ?? account.teamIds,
    rivalsDivision: clearRivalsDivision
        ? null
        : (rivalsDivision ?? account.rivalsDivision),
    weekendLeagueManualWins: clearWeekendLeagueManual
        ? null
        : (weekendLeagueManualWins ?? account.weekendLeagueManualWins),
    weekendLeagueManualLosses: clearWeekendLeagueManual
        ? null
        : (weekendLeagueManualLosses ?? account.weekendLeagueManualLosses),
    rivalsWins: rivalsWins ?? account.rivalsWins,
    rivalsLosses: rivalsLosses ?? account.rivalsLosses,
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
    weekendLeagueManualWins: json['weekend_league_manual_wins'] as int?,
    weekendLeagueManualLosses: json['weekend_league_manual_losses'] as int?,
    rivalsWins: json['rivals_wins'] as int? ?? 0,
    rivalsLosses: json['rivals_losses'] as int? ?? 0,
  );

  Map<String, dynamic> _toJson(FcAccount account) => <String, dynamic>{
    'id': account.id,
    'name': account.name,
    'is_active': account.isActive,
    'team_ids': account.teamIds,
    'rivals_division': account.rivalsDivision?.key,
    'weekend_league_manual_wins': account.weekendLeagueManualWins,
    'weekend_league_manual_losses': account.weekendLeagueManualLosses,
    'rivals_wins': account.rivalsWins,
    'rivals_losses': account.rivalsLosses,
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
