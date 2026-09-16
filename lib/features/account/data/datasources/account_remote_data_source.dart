import 'package:fifa_queue/features/account/data/models/account_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AccountRemoteDataSource {
  String? get currentUserId;

  Future<Map<String, dynamic>?> fetchById(String userId);

  Future<Map<String, dynamic>> insert({
    required String userId,
    required String displayName,
  });

  Future<Map<String, dynamic>> updateDisplayName({
    required String userId,
    required String displayName,
  });

  Future<void> updateLocale({
    required String userId,
    required String localeTag,
  });

  Future<void> touchActivity(String userId);
}

class SupabaseAccountRemoteDataSource implements AccountRemoteDataSource {
  const SupabaseAccountRemoteDataSource(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get _table => _client.from(AccountModel.table);

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<Map<String, dynamic>?> fetchById(String userId) =>
      _table.select().eq(AccountModel.columnId, userId).maybeSingle();

  @override
  Future<Map<String, dynamic>> insert({
    required String userId,
    required String displayName,
  }) => _table
      .insert(<String, dynamic>{
        AccountModel.columnId: userId,
        AccountModel.columnDisplayName: displayName,
      })
      .select()
      .single();

  @override
  Future<Map<String, dynamic>> updateDisplayName({
    required String userId,
    required String displayName,
  }) => _table
      .update(<String, dynamic>{AccountModel.columnDisplayName: displayName})
      .eq(AccountModel.columnId, userId)
      .select()
      .single();

  @override
  Future<void> updateLocale({
    required String userId,
    required String localeTag,
  }) => _table
      .update(<String, dynamic>{AccountModel.columnLocale: localeTag})
      .eq(AccountModel.columnId, userId);

  @override
  Future<void> touchActivity(String userId) => _table
      .update(<String, dynamic>{
        AccountModel.columnLastActiveAt: DateTime.now()
            .toUtc()
            .toIso8601String(),
      })
      .eq(AccountModel.columnId, userId);
}
