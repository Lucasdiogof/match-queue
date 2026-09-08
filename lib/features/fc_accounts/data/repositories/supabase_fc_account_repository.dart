import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/fc_accounts/data/datasources/fc_account_remote_data_source.dart';
import 'package:fifa_queue/features/fc_accounts/data/models/fc_account_model.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/rivals_division.dart';
import 'package:fifa_queue/features/fc_accounts/domain/repositories/fc_account_repository.dart';

class SupabaseFcAccountRepository implements FcAccountRepository {
  const SupabaseFcAccountRepository(this._dataSource, this._errorMapper);

  final FcAccountRemoteDataSource _dataSource;
  final SupabaseErrorMapper _errorMapper;

  @override
  Future<FcAccountsSnapshot> fetchMyAccounts() => _guard(() async {
    final json = await _dataSource.listMyAccounts();
    return FcAccountModel.snapshotFromResponse(json);
  });

  @override
  Future<void> createAccount(String name) =>
      _guard(() => _dataSource.createAccount(name));

  @override
  Future<void> updateAccount({required String id, required String name}) =>
      _guard(() => _dataSource.updateAccount(id: id, name: name));

  @override
  Future<void> archiveAccount(String id) =>
      _guard(() => _dataSource.archiveAccount(id));

  @override
  Future<void> updateRivalsDivision({
    required String id,
    RivalsDivision? division,
  }) => _guard(
    () => _dataSource.updateRivalsDivision(id: id, division: division?.key),
  );

  @override
  Future<void> linkToTeam({
    required String accountId,
    required String teamId,
  }) => _guard(
    () => _dataSource.linkToTeam(accountId: accountId, teamId: teamId),
  );

  @override
  Future<void> unlinkFromTeam({
    required String accountId,
    required String teamId,
  }) => _guard(
    () => _dataSource.unlinkFromTeam(accountId: accountId, teamId: teamId),
  );

  @override
  Future<void> setWeekendLeagueManualRecord({
    required String accountId,
    required String eventId,
    required int wins,
    required int losses,
  }) => _guard(
    () => _dataSource.setWeekendLeagueManualRecord(
      accountId: accountId,
      eventId: eventId,
      wins: wins,
      losses: losses,
    ),
  );

  @override
  Future<void> clearWeekendLeagueManualRecord({
    required String accountId,
    required String eventId,
  }) => _guard(
    () => _dataSource.clearWeekendLeagueManualRecord(
      accountId: accountId,
      eventId: eventId,
    ),
  );

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error) {
      throw _errorMapper.map(error);
    }
  }
}
