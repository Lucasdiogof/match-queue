// O valor no banco continua 'ADMIN' (enum team_role do Postgres): renomear a
// coluna exigiria recriar 4 funcoes ja aplicadas que comparam o literal
// 'ADMIN' num CASE. O app so precisa parar de EXIBIR "Admin" -- por isso o
// caso Dart chama manager, mas o wire value (key) permanece 'ADMIN'.
enum TeamRole {
  owner('OWNER'),
  manager('ADMIN'),
  player('PLAYER');

  const TeamRole(this.key);

  final String key;

  static TeamRole fromKey(Object? key) {
    for (final role in TeamRole.values) {
      if (role.key == key) {
        return role;
      }
    }
    return TeamRole.player;
  }

  bool get isOwner => this == TeamRole.owner;

  bool get canManageTeam => this == TeamRole.owner || this == TeamRole.manager;
}
