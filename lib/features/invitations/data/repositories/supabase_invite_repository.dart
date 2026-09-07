import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/invitations/data/datasources/invite_remote_data_source.dart';
import 'package:fifa_queue/features/invitations/data/models/invite_preview_model.dart';
import 'package:fifa_queue/features/invitations/data/models/join_team_result_model.dart';
import 'package:fifa_queue/features/invitations/data/models/team_invite_model.dart';
import 'package:fifa_queue/features/invitations/domain/entities/invite_preview.dart';
import 'package:fifa_queue/features/invitations/domain/entities/join_team_result.dart';
import 'package:fifa_queue/features/invitations/domain/entities/team_invite.dart';
import 'package:fifa_queue/features/invitations/domain/repositories/invite_repository.dart';

class SupabaseInviteRepository implements InviteRepository {
  const SupabaseInviteRepository(this._dataSource, this._errorMapper);

  final InviteRemoteDataSource _dataSource;
  final SupabaseErrorMapper _errorMapper;

  @override
  Future<InvitePreview> resolveInvite(String code) => _guard(() async {
    final json = await _dataSource.resolveInvite(code);
    return InvitePreviewModel.fromJson(json);
  });

  @override
  Future<JoinTeamResult> joinTeam(String code) => _guard(() async {
    final json = await _dataSource.joinTeam(code);
    return JoinTeamResultModel.fromJson(json);
  });

  @override
  Future<TeamInvite> getOrCreateActiveInvite(String teamId) => _guard(() async {
    final json = await _dataSource.getOrCreateActiveInvite(teamId);
    return TeamInviteModel.fromJson(json);
  });

  @override
  Future<TeamInvite> rotateInvite(String teamId) => _guard(() async {
    final json = await _dataSource.rotateInvite(teamId);
    return TeamInviteModel.fromJson(json);
  });

  @override
  Future<void> revokeInvite(String teamId) =>
      _guard(() => _dataSource.revokeInvite(teamId));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error) {
      throw _errorMapper.map(error);
    }
  }
}
