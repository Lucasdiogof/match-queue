import 'package:fifa_queue/features/profile/data/models/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class ProfileRemoteDataSource {
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

  Future<void> updateLocale({required String userId, required String localeTag});
}

class SupabaseProfileRemoteDataSource implements ProfileRemoteDataSource {
  const SupabaseProfileRemoteDataSource(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get _table => _client.from(ProfileModel.table);

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<Map<String, dynamic>?> fetchById(String userId) =>
      _table.select().eq(ProfileModel.columnId, userId).maybeSingle();

  @override
  Future<Map<String, dynamic>> insert({
    required String userId,
    required String displayName,
  }) => _table
      .insert(<String, dynamic>{
        ProfileModel.columnId: userId,
        ProfileModel.columnDisplayName: displayName,
      })
      .select()
      .single();

  @override
  Future<Map<String, dynamic>> updateDisplayName({
    required String userId,
    required String displayName,
  }) => _table
      .update(<String, dynamic>{ProfileModel.columnDisplayName: displayName})
      .eq(ProfileModel.columnId, userId)
      .select()
      .single();

  @override
  Future<void> updateLocale({
    required String userId,
    required String localeTag,
  }) => _table
      .update(<String, dynamic>{ProfileModel.columnLocale: localeTag})
      .eq(ProfileModel.columnId, userId);
}
