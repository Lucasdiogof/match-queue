import 'package:fifa_queue/features/requests/domain/entities/invite_target_preview.dart';
import 'package:fifa_queue/features/requests/domain/entities/requests_inbox.dart';

abstract interface class RequestsRepository {
  /// Convites recebidos pelo usuario + pedidos pendentes dos times que ele
  /// administra, numa chamada so.
  Future<RequestsInbox> fetchInbox();

  /// Usuario pede pra entrar num time com um Elenco proprio.
  Future<void> requestToJoin({
    required String teamId,
    required String fcAccountId,
  });

  /// Id do proprio pedido PENDING pra este time, se houver -- pra tela
  /// publica do time saber se deve mostrar "Pedir para entrar" ou
  /// "Solicitacao enviada" sem depender so de estado local em memoria.
  Future<String?> myPendingRequestId(String teamId);

  /// So o proprio solicitante cancela, e so enquanto PENDING.
  Future<void> cancelJoinRequest(String requestId);

  /// OWNER/ADMIN aprova: cria membership + vincula o Elenco.
  Future<void> approveJoinRequest(String requestId);

  /// OWNER/ADMIN recusa. Nao cria membership.
  Future<void> rejectJoinRequest(String requestId);

  /// Preview do alvo do convite antes de enviar.
  Future<InviteTargetPreview> resolveInviteTarget(String slug);

  /// OWNER/ADMIN convida um jogador pelo slug do perfil publico dele.
  Future<void> inviteMember({required String teamId, required String slug});

  /// OWNER/ADMIN revoga um convite PENDING enviado pelo proprio time.
  Future<void> revokeInvitation(String invitationId);

  /// So o proprio convidado responde. Aceitar cria membership.
  Future<void> respondInvitation({
    required String invitationId,
    required bool accept,
  });

  /// Emite um evento sempre que algo pendente pra este usuario muda (pedido
  /// recebido por um time que ele administra, ou convite direto). Nunca
  /// carrega dado -- so avisa pra re-buscar [fetchInbox].
  Stream<void> watchChanges();

  /// Convites PENDING que o proprio time enviou -- pra tela do time poder
  /// listar e oferecer cancelar. OWNER/ADMIN only.
  Future<List<SentTeamInvitation>> fetchSentInvitations(String teamId);
}
