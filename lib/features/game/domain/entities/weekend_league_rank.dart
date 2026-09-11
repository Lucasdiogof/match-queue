/// Rank de FUT Champions: 15 jogos, um rank por número de vitórias (perdas
/// não entram na conta). Tabela oficial fornecida pelo dono do produto --
/// nunca inventar faixa/nome aqui.
enum WeekendLeagueTier { elite, champion, contender }

class WeekendLeagueRank {
  const WeekendLeagueRank({
    required this.tier,
    required this.tierRank,
    required this.overallRank,
  });

  final WeekendLeagueTier tier;

  /// 1 a 5 dentro do tier (I a V).
  final int tierRank;

  /// 1 a 15, onde 1 é 15 vitórias (o melhor).
  final int overallRank;

  String get tierRankRoman => const <int, String>{
    1: 'I',
    2: 'II',
    3: 'III',
    4: 'IV',
    5: 'V',
  }[tierRank]!;

  /// Nulo com 0 vitórias: nenhuma campanha rende rank.
  static WeekendLeagueRank? fromWins(int wins) {
    if (wins < 1 || wins > 15) {
      return null;
    }
    final overallRank = 16 - wins;
    final tierRank = ((overallRank - 1) % 5) + 1;
    final tier = wins >= 11
        ? WeekendLeagueTier.elite
        : wins >= 6
        ? WeekendLeagueTier.champion
        : WeekendLeagueTier.contender;
    return WeekendLeagueRank(
      tier: tier,
      tierRank: tierRank,
      overallRank: overallRank,
    );
  }
}
