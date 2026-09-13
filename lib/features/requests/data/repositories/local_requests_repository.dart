import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/requests/domain/entities/invite_target_preview.dart';
import 'package:fifa_queue/features/requests/domain/entities/requests_inbox.dart';
import 'package:fifa_queue/features/requests/domain/repositories/requests_repository.dart';

/// Modo local e mono-usuario: nunca ha outro usuario pra convidar nem outro
/// time administrando o mesmo pedido, entao a caixa de entrada fica sempre
/// vazia e nenhuma acao tem alvo valido.
class LocalRequestsRepository implements RequestsRepository {
  const LocalRequestsRepository();

  @override
  Future<RequestsInbox> fetchInbox() async => const RequestsInbox.empty();

  @override
  Future<void> requestToJoin({
    required String teamId,
    required String fcAccountId,
  }) async {
    throw const TeamFailure(reason: TeamFailureReason.notFound);
  }

  @override
  Future<void> cancelJoinRequest(String requestId) async {
    throw const TeamFailure(reason: TeamFailureReason.requestNotFound);
  }

  @override
  Future<void> approveJoinRequest(String requestId) async {
    throw const TeamFailure(reason: TeamFailureReason.requestNotFound);
  }

  @override
  Future<void> rejectJoinRequest(String requestId) async {
    throw const TeamFailure(reason: TeamFailureReason.requestNotFound);
  }

  @override
  Future<String?> myPendingRequestId(String teamId) async => null;

  @override
  Future<InviteTargetPreview> resolveInviteTarget(String slug) async =>
      const InviteTargetPreview.notFound();

  @override
  Future<void> inviteMember({
    required String teamId,
    required String slug,
  }) async {
    throw const TeamFailure(reason: TeamFailureReason.notFound);
  }

  @override
  Future<void> revokeInvitation(String invitationId) async {
    throw const TeamFailure(reason: TeamFailureReason.requestNotFound);
  }

  @override
  Future<void> respondInvitation({
    required String invitationId,
    required bool accept,
  }) async {
    throw const TeamFailure(reason: TeamFailureReason.requestNotFound);
  }

  @override
  Stream<void> watchChanges() => const Stream<void>.empty();
}
