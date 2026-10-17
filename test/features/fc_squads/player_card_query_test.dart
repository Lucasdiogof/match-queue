import 'package:fifa_queue/features/fc_squads/domain/repositories/player_card_catalog_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nextPage keeps every filter and only advances the offset', () {
    const query = PlayerCardQuery(
      query: 'silva',
      positions: <String>['CB', 'LB', 'RB'],
      limit: 30,
      cardType: 'TOTW',
      clubId: 'club-1',
    );

    final next = query.nextPage();

    expect(next.offset, 30);
    expect(next.positions, query.positions);
    expect(next.cardType, 'TOTW');
    expect(next.clubId, 'club-1');
    expect(next.query, 'silva');
  });
}
