import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/requests/data/datasources/requests_remote_data_source.dart';
import 'package:fifa_queue/features/requests/data/models/invite_target_preview_model.dart';
import 'package:fifa_queue/features/requests/data/models/requests_inbox_model.dart';
import 'package:fifa_queue/features/requests/domain/entities/invite_target_preview.dart';
import 'package:fifa_queue/features/requests/domain/entities/requests_inbox.dart';
import 'package:fifa_queue/features/requests/domain/repositories/requests_repository.dart';

class SupabaseRequestsRepository implements RequestsRepository {
  const SupabaseRequestsRepository(this._dataSource, this._errorMapper);

  final RequestsRemoteDataSource _dataSource;
  final SupabaseErrorMapper _errorMapper;

  @override
  Future<RequestsInbox> fetchInbox() => _guard(
    () async => RequestsInboxModel.fromJson(await _dataSource.getRequestsInbox()),
  );

  @override
  Future<void> requestToJoin({
    required String teamId,
    required String fcAccountId,
  }) => _guard(
    () => _dataSource.requestTeamJoin(teamId: teamId, fcAccountId: fcAccountId),
  );

  @override
  Future<void> cancelJoinRequest(String requestId) =>
      _guard(() => _dataSource.cancelTeamJoinRequest(requestId));

  @override
  Future<void> approveJoinRequest(String requestId) =>
      _guard(() => _dataSource.approveTeamJoinRequest(requestId));

  @override
  Future<void> rejectJoinRequest(String requestId) =>
      _guard(() => _dataSource.rejectTeamJoinRequest(requestId));

  @override
  Future<InviteTargetPreview> resolveInviteTarget(String slug) => _guard(
    () async =>
        InviteTargetPreviewModel.fromJson(await _dataSource.resolveInviteTarget(slug)),
  );

  @override
  Future<void> inviteMember({required String teamId, required String slug}) =>
      _guard(() => _dataSource.inviteTeamMember(teamId: teamId, slug: slug));

  @override
  Future<void> revokeInvitation(String invitationId) =>
      _guard(() => _dataSource.revokeTeamInvitation(invitationId));

  @override
  Future<void> respondInvitation({
    required String invitationId,
    required bool accept,
  }) => _guard(
    () => _dataSource.respondTeamInvitation(
      invitationId: invitationId,
      accept: accept,
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
