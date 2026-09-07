enum TeamRole {
  owner('OWNER'),
  admin('ADMIN'),
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

  bool get canManageTeam => this == TeamRole.owner || this == TeamRole.admin;
}
