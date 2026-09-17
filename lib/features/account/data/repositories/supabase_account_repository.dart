import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/core/validation/app_validators.dart';
import 'package:fifa_queue/features/account/data/datasources/account_remote_data_source.dart';
import 'package:fifa_queue/features/account/data/models/account_model.dart';
import 'package:fifa_queue/features/account/domain/entities/account.dart';
import 'package:fifa_queue/features/account/domain/entities/account_stats.dart';
import 'package:fifa_queue/features/account/domain/entities/platform.dart';
import 'package:fifa_queue/features/account/domain/entities/rivals_division.dart';
import 'package:fifa_queue/features/account/domain/repositories/account_repository.dart';
import 'package:fifa_queue/features/game/data/models/weekend_league_event_model.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_event.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAccountRepository implements AccountRepository {
  const SupabaseAccountRepository(this._dataSource, this._errorMapper);

  final AccountRemoteDataSource _dataSource;
  final SupabaseErrorMapper _errorMapper;

  @override
  Future<Account?> fetchMyAccount() => _guard(() async {
    final json = await _dataSource.fetchById(_requireUserId());
    if (json == null) {
      return null;
    }
    return _withExtras(AccountModel.fromJson(json));
  });

  @override
  Future<Account> ensureMyAccount({required String fallbackDisplayName}) =>
      _guard(() async {
        final userId = _requireUserId();
        final existing = await _dataSource.fetchById(userId);
        final base = existing != null
            ? AccountModel.fromJson(existing)
            : AccountModel.fromJson(
                await _insertOrFetchExisting(userId, fallbackDisplayName),
              );
        return _withExtras(base);
      });

  /// O trigger `handle_new_user` já cria a linha em `public.users` logo após
  /// o cadastro -- às vezes antes desta leitura conseguir vê-la (mesma conta,
  /// duas escritas correndo: a do trigger e esta). Sem isso, o insert cai
  /// num unique_violation e a tela de Conta mostrava "algo deu errado no
  /// servidor" na primeira tentativa logo após criar a conta, mesmo a linha
  /// já existindo -- só funcionava ao tentar de novo, quando a leitura já
  /// enxergava o que o trigger tinha gravado.
  Future<Map<String, dynamic>> _insertOrFetchExisting(
    String userId,
    String fallbackDisplayName,
  ) async {
    try {
      return await _dataSource.insert(
        userId: userId,
        displayName: _sanitize(fallbackDisplayName),
      );
    } on PostgrestException catch (error) {
      if (error.code != '23505') {
        rethrow;
      }
      final existing = await _dataSource.fetchById(userId);
      if (existing == null) {
        rethrow;
      }
      return existing;
    }
  }

  @override
  Future<Account> updateDisplayName(String displayName) => _guard(() async {
    final updated = await _dataSource.updateDisplayName(
      userId: _requireUserId(),
      displayName: _sanitize(displayName),
    );
    return _withExtras(AccountModel.fromJson(updated));
  });

  @override
  Future<void> updateLocale(String localeTag) => _guard(
    () => _dataSource.updateLocale(
      userId: _requireUserId(),
      localeTag: localeTag,
    ),
  );

  @override
  Future<void> touchActivity() =>
      _guard(() => _dataSource.touchActivity(_requireUserId()));

  @override
  Future<List<Platform>> updatePlatforms(List<Platform> platforms) =>
      _guard(() async {
        final saved = await _dataSource.updatePlatforms(
          platforms.map((p) => p.key).toList(growable: false),
        );
        return <Platform>[
          for (final key in saved)
            if (Platform.tryFromKey(key) != null) Platform.tryFromKey(key)!,
        ];
      });

  @override
  Future<void> updateRivalsDivision(RivalsDivision? division) =>
      _guard(() => _dataSource.updateRivalsDivision(division?.key));

  @override
  Future<void> incrementRivalsRecord({int winDelta = 0, int lossDelta = 0}) =>
      _guard(
        () => _dataSource.incrementRivalsRecord(
          winDelta: winDelta,
          lossDelta: lossDelta,
        ),
      );

  @override
  Future<void> incrementWeekendLeagueRecord({
    required String eventId,
    int winDelta = 0,
    int lossDelta = 0,
  }) => _guard(
    () => _dataSource.incrementWeekendLeagueRecord(
      eventId: eventId,
      winDelta: winDelta,
      lossDelta: lossDelta,
    ),
  );

  @override
  Future<void> setWeekendLeagueManualRecord({
    required String eventId,
    required int wins,
    required int losses,
  }) => _guard(
    () => _dataSource.setWeekendLeagueManualRecord(
      eventId: eventId,
      wins: wins,
      losses: losses,
    ),
  );

  @override
  Future<void> clearWeekendLeagueManualRecord(String eventId) =>
      _guard(() => _dataSource.clearWeekendLeagueManualRecord(eventId));

  @override
  Future<List<WeekendLeagueEvent>> fetchWeekendLeagueEvents() =>
      _guard(() async {
        final rows = await _dataSource.fetchWeekendLeagueEvents();
        return <WeekendLeagueEvent>[
          for (final row in rows) ?WeekendLeagueEventModel.fromResponse(row),
        ];
      });

  @override
  Future<WeekendLeagueAccountStats> fetchWeekendLeagueStats(String eventId) =>
      _guard(() async {
        final json = await _dataSource.fetchWeekendLeagueStats(eventId);
        return WeekendLeagueAccountStats.fromJson(json);
      });

  @override
  Future<RivalsAccountStats> fetchRivalsStats() => _guard(() async {
    final json = await _dataSource.fetchRivalsStats();
    return RivalsAccountStats.fromJson(json);
  });

  Future<Account> _withExtras(Account base) async {
    final extras = await _dataSource.fetchAccountExtras();
    return AccountModel.mergeExtras(base, extras);
  }

  String _requireUserId() {
    final userId = _dataSource.currentUserId;
    if (userId == null || userId.isEmpty) {
      throw const AuthFailure(reason: AuthFailureReason.sessionExpired);
    }
    return userId;
  }

  String _sanitize(String displayName) {
    final normalized = AppValidators.normalizeDisplayName(displayName);
    if (normalized.isEmpty) {
      return 'Jogador';
    }
    final runes = normalized.runes.toList();
    if (runes.length <= AppValidators.displayNameMaxLength) {
      return normalized;
    }
    return String.fromCharCodes(runes.take(AppValidators.displayNameMaxLength));
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error) {
      throw _errorMapper.map(error);
    }
  }
}
