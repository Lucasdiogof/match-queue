import 'package:fifa_queue/features/teams/data/models/player_profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _weekendLeagueRow({
  Object? season = '2026',
  Object? number = 3,
}) => <String, dynamic>{
  'event_id': 'evt-1',
  'number': number,
  'season': season,
  'starts_at': '2026-09-05T00:00:00Z',
  'wins': 10,
  'losses': 5,
};

Map<String, dynamic> _profileJson({
  List<dynamic> weekendLeagueHistory = const <dynamic>[],
}) => <String, dynamic>{
  'user_id': 'u1',
  'display_name': 'Lucas',
  'avatar_url': null,
  'candidate_accounts': <dynamic>[],
  'needs_account_selection': false,
  'account': null,
  'squad': null,
  'weekend_league_history': weekendLeagueHistory,
};

void main() {
  group('season de Champions e texto, nunca numero', () {
    test('temporada como texto (ex: "2026") nao derruba o parsing', () {
      final profile = PlayerProfileModel.fromJson(
        _profileJson(
          weekendLeagueHistory: <dynamic>[_weekendLeagueRow(season: '2026')],
        ),
      );

      expect(profile.weekendLeagueHistory, hasLength(1));
      expect(profile.weekendLeagueHistory.single.season, '2026');
    });

    test('temporada ausente vira null, nunca 0 fabricado', () {
      final profile = PlayerProfileModel.fromJson(
        _profileJson(
          weekendLeagueHistory: <dynamic>[_weekendLeagueRow(season: null)],
        ),
      );

      expect(profile.weekendLeagueHistory.single.season, isNull);
    });
  });

  test('perfil sem conta vinculada nao quebra e fica com listas vazias', () {
    final profile = PlayerProfileModel.fromJson(_profileJson());

    expect(profile.account, isNull);
    expect(profile.squad, isNull);
    expect(profile.candidateAccounts, isEmpty);
    expect(profile.weekendLeagueHistory, isEmpty);
  });
}
