import 'package:fifa_queue/features/game/domain/entities/weekend_league_rank.dart';

/// Elite/Champion/Contender são os nomes oficiais do rank de FUT Champions
/// -- mesmos em PT/EN/ES nas fontes que temos, então não tem chave de
/// tradução própria (igual "Elite" em RivalsDivision).
extension WeekendLeagueRankLabel on WeekendLeagueRank {
  String get tierName => switch (tier) {
    WeekendLeagueTier.elite => 'Elite',
    WeekendLeagueTier.champion => 'Champion',
    WeekendLeagueTier.contender => 'Contender',
  };

  String get label => '$tierName $tierRankRoman';
}
