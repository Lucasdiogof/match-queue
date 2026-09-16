import 'package:fifa_queue/features/teams/domain/entities/team_member_permissions.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_role.dart';
import 'package:flutter_test/flutter_test.dart';

// Espelho dos casos que o servidor valida em remove_team_member,
// set_team_member_role e transfer_team_ownership. Se algum dia a matriz do
// Postgres mudar, estes testes precisam mudar junto -- eles existem
// exatamente pra que a divergencia apareca aqui, e nao numa acao que some
// da UI (ou pior, aparece e falha no servidor).
void main() {
  group('remocao de membro', () {
    test('OWNER remove PLAYER e MANAGER', () {
      expect(
        TeamMemberPermissions.canRemove(
          viewer: TeamRole.owner,
          target: TeamRole.player,
        ),
        isTrue,
      );
      expect(
        TeamMemberPermissions.canRemove(
          viewer: TeamRole.owner,
          target: TeamRole.manager,
        ),
        isTrue,
      );
    });

    test('MANAGER remove PLAYER, mas nao outro MANAGER', () {
      expect(
        TeamMemberPermissions.canRemove(
          viewer: TeamRole.manager,
          target: TeamRole.player,
        ),
        isTrue,
      );
      expect(
        TeamMemberPermissions.canRemove(
          viewer: TeamRole.manager,
          target: TeamRole.manager,
        ),
        isFalse,
      );
    });

    test('ninguem remove o OWNER', () {
      for (final viewer in TeamRole.values) {
        expect(
          TeamMemberPermissions.canRemove(
            viewer: viewer,
            target: TeamRole.owner,
          ),
          isFalse,
          reason: '$viewer nao pode remover o OWNER',
        );
      }
    });

    test('PLAYER nao remove ninguem', () {
      for (final target in TeamRole.values) {
        expect(
          TeamMemberPermissions.canRemove(
            viewer: TeamRole.player,
            target: target,
          ),
          isFalse,
          reason: 'PLAYER nao pode remover $target',
        );
      }
    });
  });

  group('cargo', () {
    test('so OWNER promove PLAYER para MANAGER', () {
      expect(
        TeamMemberPermissions.canPromoteToManager(
          viewer: TeamRole.owner,
          target: TeamRole.player,
        ),
        isTrue,
      );
      expect(
        TeamMemberPermissions.canPromoteToManager(
          viewer: TeamRole.manager,
          target: TeamRole.player,
        ),
        isFalse,
      );
      expect(
        TeamMemberPermissions.canPromoteToManager(
          viewer: TeamRole.player,
          target: TeamRole.player,
        ),
        isFalse,
      );
    });

    test('so OWNER rebaixa MANAGER para PLAYER', () {
      expect(
        TeamMemberPermissions.canDemoteToPlayer(
          viewer: TeamRole.owner,
          target: TeamRole.manager,
        ),
        isTrue,
      );
      expect(
        TeamMemberPermissions.canDemoteToPlayer(
          viewer: TeamRole.manager,
          target: TeamRole.manager,
        ),
        isFalse,
      );
    });

    test('OWNER nunca e alvo de mudanca de cargo', () {
      for (final viewer in TeamRole.values) {
        expect(
          TeamMemberPermissions.canPromoteToManager(
            viewer: viewer,
            target: TeamRole.owner,
          ),
          isFalse,
        );
        expect(
          TeamMemberPermissions.canDemoteToPlayer(
            viewer: viewer,
            target: TeamRole.owner,
          ),
          isFalse,
        );
      }
    });
  });

  group('transferencia de propriedade', () {
    test('so OWNER transfere, e so para quem ainda nao e OWNER', () {
      expect(
        TeamMemberPermissions.canTransferOwnership(
          viewer: TeamRole.owner,
          target: TeamRole.player,
        ),
        isTrue,
      );
      expect(
        TeamMemberPermissions.canTransferOwnership(
          viewer: TeamRole.owner,
          target: TeamRole.manager,
        ),
        isTrue,
      );
      expect(
        TeamMemberPermissions.canTransferOwnership(
          viewer: TeamRole.owner,
          target: TeamRole.owner,
        ),
        isFalse,
      );
    });

    test('MANAGER e PLAYER nunca transferem', () {
      for (final target in TeamRole.values) {
        expect(
          TeamMemberPermissions.canTransferOwnership(
            viewer: TeamRole.manager,
            target: target,
          ),
          isFalse,
        );
        expect(
          TeamMemberPermissions.canTransferOwnership(
            viewer: TeamRole.player,
            target: target,
          ),
          isFalse,
        );
      }
    });
  });

  group('menu do membro', () {
    test('nunca aparece para o OWNER como alvo', () {
      for (final viewer in TeamRole.values) {
        expect(
          TeamMemberPermissions.hasAnyAction(
            viewer: viewer,
            target: TeamRole.owner,
          ),
          isFalse,
        );
      }
    });

    test('nunca aparece para um PLAYER olhando', () {
      for (final target in TeamRole.values) {
        expect(
          TeamMemberPermissions.hasAnyAction(
            viewer: TeamRole.player,
            target: target,
          ),
          isFalse,
        );
      }
    });

    test('MANAGER so tem acao sobre PLAYER', () {
      expect(
        TeamMemberPermissions.hasAnyAction(
          viewer: TeamRole.manager,
          target: TeamRole.player,
        ),
        isTrue,
      );
      expect(
        TeamMemberPermissions.hasAnyAction(
          viewer: TeamRole.manager,
          target: TeamRole.manager,
        ),
        isFalse,
      );
    });
  });
}
