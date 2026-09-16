import 'package:fifa_queue/features/teams/domain/entities/team_role.dart';

/// Espelho client-side da matriz que o servidor ja valida em
/// remove_team_member / set_team_member_role / transfer_team_ownership.
///
/// Serve SO pra decidir o que MOSTRAR: o servidor recusa de qualquer jeito
/// se a UI errar (nenhuma dessas regras depende de um papel enviado pelo
/// cliente -- o Postgres resolve o papel real a partir de auth.uid()). Sem
/// isto a matriz vivia espalhada em condicoes de PopupMenuItem, onde nao dava
/// pra testar nem conferir contra o servidor lado a lado.
abstract final class TeamMemberPermissions {
  /// OWNER remove PLAYER e MANAGER; MANAGER remove so PLAYER. OWNER nunca e
  /// removido por ninguem -- sai do time transferindo a posse ou excluindo
  /// o proprio Perfil.
  static bool canRemove({required TeamRole viewer, required TeamRole target}) {
    if (target == TeamRole.owner) {
      return false;
    }
    return switch (viewer) {
      TeamRole.owner => true,
      TeamRole.manager => target == TeamRole.player,
      TeamRole.player => false,
    };
  }

  /// Promover PLAYER -> MANAGER. So o OWNER mexe em cargo.
  static bool canPromoteToManager({
    required TeamRole viewer,
    required TeamRole target,
  }) => viewer == TeamRole.owner && target == TeamRole.player;

  /// Rebaixar MANAGER -> PLAYER. So o OWNER mexe em cargo.
  static bool canDemoteToPlayer({
    required TeamRole viewer,
    required TeamRole target,
  }) => viewer == TeamRole.owner && target == TeamRole.manager;

  /// So o OWNER passa a posse, e so pra quem ainda nao e OWNER.
  static bool canTransferOwnership({
    required TeamRole viewer,
    required TeamRole target,
  }) => viewer == TeamRole.owner && target != TeamRole.owner;

  /// Existe alguma acao administrativa disponivel para este par? Usado pra
  /// decidir se o menu do membro aparece.
  static bool hasAnyAction({
    required TeamRole viewer,
    required TeamRole target,
  }) =>
      canRemove(viewer: viewer, target: target) ||
      canPromoteToManager(viewer: viewer, target: target) ||
      canDemoteToPlayer(viewer: viewer, target: target) ||
      canTransferOwnership(viewer: viewer, target: target);
}
