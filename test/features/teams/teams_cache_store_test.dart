import 'package:fifa_queue/features/teams/data/teams_cache_store.dart';
import 'package:fifa_queue/features/teams/domain/entities/team.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_membership.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_role.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

UserTeam _team(String id) => UserTeam(
  team: Team(
    id: id,
    name: 'Team $id',
    tag: 'T$id',
    defaultSearchDuration: const Duration(seconds: 180),
    isActive: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 2),
  ),
  role: TeamRole.owner,
  joinedAt: DateTime.utc(2026, 1, 3),
);

void main() {
  late TeamsCacheStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    store = TeamsCacheStore(await SharedPreferences.getInstance());
  });

  test('round-trips the team list with the save time', () async {
    final savedAt = DateTime.utc(2026, 10, 15, 20);
    await store.write('u1', <UserTeam>[_team('a'), _team('b')], now: savedAt);

    final cached = store.read('u1');

    expect(cached!.value, <UserTeam>[_team('a'), _team('b')]);
    expect(cached.savedAt, savedAt);
  });

  test('never returns another user\'s teams, and clear removes them', () async {
    await store.write('u1', <UserTeam>[_team('a')]);

    expect(store.read('u2'), isNull);

    await store.clear();
    expect(store.read('u1'), isNull);
  });
}
