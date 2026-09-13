import 'package:fifa_queue/features/public_profile/data/models/public_profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json({
  Map<String, dynamic>? weekendLeague,
  Map<String, dynamic>? rivals,
}) => <String, dynamic>{
  'schema_version': 1,
  'found': true,
  'profile': <String, dynamic>{'display_name': 'Lucas', 'avatar_url': null},
  'account': <String, dynamic>{'name': 'Conta QA', 'rivals_division': 'ELITE'},
  'stats': null,
  'weekend_league': weekendLeague,
  'rivals': rivals,
  'squad': null,
};

void main() {
  group('perfil publico usa o contador manual, nunca o computado', () {
    test('weekend_league.manual vira o record exibido', () {
      final profile = publicProfileFromJson(
        _json(
          weekendLeague: <String, dynamic>{
            'computed': <String, dynamic>{
              'matches_count': 0,
              'wins': 0,
              'losses': 0,
              'goals_for': 0,
              'goals_against': 0,
              'goal_diff': 0,
            },
            'manual': <String, dynamic>{'wins': 12, 'losses': 3},
          },
        ),
      );

      expect(profile.weekendLeague?.wins, 12);
      expect(profile.weekendLeague?.losses, 3);
    });

    test('rivals.manual vira o record exibido', () {
      final profile = publicProfileFromJson(
        _json(
          rivals: <String, dynamic>{
            'aggregate': <String, dynamic>{
              'matches_count': 0,
              'wins': 0,
              'losses': 0,
              'goals_for': 0,
              'goals_against': 0,
              'goal_diff': 0,
            },
            'manual': <String, dynamic>{'wins': 125, 'losses': 1},
          },
        ),
      );

      expect(profile.rivals?.wins, 125);
      expect(profile.rivals?.losses, 1);
    });

    test('secao ausente (toggle desligado) fica null, nunca 0 fabricado', () {
      final profile = publicProfileFromJson(_json());

      expect(profile.weekendLeague, isNull);
      expect(profile.rivals, isNull);
    });
  });
}
