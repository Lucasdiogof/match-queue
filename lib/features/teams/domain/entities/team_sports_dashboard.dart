import 'package:equatable/equatable.dart';

/// Números do Time inteiro.
///
/// [goalsFor]/[goalsAgainst] vêm do placar das partidas; [registeredPlayerGoals]
/// vem dos gols registrados por jogador. São fontes diferentes e não precisam
/// bater — uma vitória sem placar entra no record sem somar gol, e um gol
/// registrado entra na artilharia mesmo sem placar.
class TeamSportsSummary extends Equatable {
  const TeamSportsSummary({
    required this.membersCount,
    required this.accountsCount,
    required this.matches,
    required this.wins,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.registeredPlayerGoals,
    required this.registeredAssists,
    this.winRate,
  });

  final int membersCount;
  final int accountsCount;
  final int matches;
  final int wins;
  final int losses;

  /// `null` quando não há partida concluída — nunca 0, que leria como
  /// "sempre perdeu".
  final double? winRate;

  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int registeredPlayerGoals;
  final int registeredAssists;

  bool get hasMatches => matches > 0;

  @override
  List<Object?> get props => <Object?>[
    membersCount,
    accountsCount,
    matches,
    wins,
    losses,
    winRate,
    goalsFor,
    goalsAgainst,
    goalDifference,
    registeredPlayerGoals,
    registeredAssists,
  ];
}

/// Linha do ranking interno. Sempre por USUÁRIO: se ele tem várias Contas
/// vinculadas ao Time, elas somam aqui e o detalhe mostra a quebra.
class TeamMemberSportsStats extends Equatable {
  const TeamMemberSportsStats({
    required this.userId,
    required this.displayName,
    required this.accountsCount,
    required this.matches,
    required this.wins,
    required this.losses,
    required this.playerGoals,
    required this.playerAssists,
    required this.isRanked,
    this.avatarUrl,
    this.winRate,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int accountsCount;
  final int matches;
  final int wins;
  final int losses;
  final double? winRate;
  final int goalsFor;
  final int goalsAgainst;
  final int playerGoals;
  final int playerAssists;

  /// Atingiu o mínimo de partidas para disputar o ranking em pé de igualdade.
  /// Quem não atingiu aparece igual, marcado e ordenado depois.
  final bool isRanked;

  bool get hasMatches => matches > 0;

  bool get hasMultipleAccounts => accountsCount > 1;

  @override
  List<Object?> get props => <Object?>[
    userId,
    displayName,
    avatarUrl,
    accountsCount,
    matches,
    wins,
    losses,
    winRate,
    goalsFor,
    goalsAgainst,
    playerGoals,
    playerAssists,
    isRanked,
  ];
}

/// Uma linha de artilharia/assistências: performance de uma CARTA numa CONTA.
/// A mesma carta em duas Contas são duas linhas — o gol tem dono.
class TeamPlayerLeaderboardEntry extends Equatable {
  const TeamPlayerLeaderboardEntry({
    required this.playerKey,
    required this.playerName,
    required this.goals,
    required this.assists,
    required this.userId,
    required this.displayName,
    required this.fcAccountId,
    required this.accountName,
    this.playerCardId,
  });

  final String playerKey;
  final String? playerCardId;
  final String playerName;
  final int goals;
  final int assists;
  final String userId;
  final String displayName;
  final String fcAccountId;
  final String accountName;

  String get initials {
    final parts = playerName.trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return _take(parts.first, 2).toUpperCase();
    }
    return '${_take(parts.first, 1)}${_take(parts.last, 1)}'.toUpperCase();
  }

  static String _take(String value, int count) =>
      String.fromCharCodes(value.runes.take(count));

  @override
  List<Object?> get props => <Object?>[
    playerKey,
    playerCardId,
    playerName,
    goals,
    assists,
    userId,
    fcAccountId,
  ];
}

/// Record de Weekend League de uma Conta no evento corrente.
/// [isManual] indica que o usuário informou o W/L à mão — o que vale para
/// exibição, mas nunca fabrica gol nem assistência.
class TeamWeekendLeagueEntry extends Equatable {
  const TeamWeekendLeagueEntry({
    required this.userId,
    required this.displayName,
    required this.fcAccountId,
    required this.accountName,
    required this.wins,
    required this.losses,
    required this.isManual,
  });

  final String userId;
  final String displayName;
  final String fcAccountId;
  final String accountName;
  final int wins;
  final int losses;
  final bool isManual;

  bool get hasRecord => wins > 0 || losses > 0;

  @override
  List<Object?> get props => <Object?>[
    userId,
    fcAccountId,
    accountName,
    wins,
    losses,
    isManual,
  ];
}

/// Situação de Rivals de uma Conta. [division] é informação, não posição:
/// o domínio não modela ordem oficial entre divisões, então não se inventa
/// um ranking a partir dela.
class TeamRivalsEntry extends Equatable {
  const TeamRivalsEntry({
    required this.userId,
    required this.displayName,
    required this.fcAccountId,
    required this.accountName,
    required this.matches,
    required this.wins,
    required this.losses,
    this.division,
    this.winRate,
  });

  final String userId;
  final String displayName;
  final String fcAccountId;
  final String accountName;
  final String? division;
  final int matches;
  final int wins;
  final int losses;
  final double? winRate;

  @override
  List<Object?> get props => <Object?>[
    userId,
    fcAccountId,
    division,
    matches,
    wins,
    losses,
    winRate,
  ];
}

/// Evento esportivo recente. Nada de fila/busca: só o que aconteceu em campo.
class TeamSportsActivity extends Equatable {
  const TeamSportsActivity({
    required this.occurredAt,
    required this.userId,
    required this.displayName,
    required this.accountName,
    required this.gameMode,
    required this.result,
    this.avatarUrl,
    this.goalsFor,
    this.goalsAgainst,
    this.topScorerName,
    this.topScorerGoals,
  });

  final DateTime occurredAt;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String accountName;
  final String gameMode;
  final String result;
  final int? goalsFor;
  final int? goalsAgainst;
  final String? topScorerName;
  final int? topScorerGoals;

  bool get isWin => result == 'WIN';

  bool get hasScore => goalsFor != null && goalsAgainst != null;

  @override
  List<Object?> get props => <Object?>[
    occurredAt,
    userId,
    accountName,
    gameMode,
    result,
    goalsFor,
    goalsAgainst,
    topScorerName,
    topScorerGoals,
  ];
}

class TeamSportsDashboard extends Equatable {
  const TeamSportsDashboard({
    required this.teamId,
    required this.summary,
    required this.ranking,
    required this.topScorers,
    required this.topAssists,
    required this.weekendLeague,
    required this.rivals,
    required this.activity,
    required this.minRankedMatches,
  });

  final String teamId;
  final TeamSportsSummary summary;
  final List<TeamMemberSportsStats> ranking;
  final List<TeamPlayerLeaderboardEntry> topScorers;
  final List<TeamPlayerLeaderboardEntry> topAssists;
  final List<TeamWeekendLeagueEntry> weekendLeague;
  final List<TeamRivalsEntry> rivals;
  final List<TeamSportsActivity> activity;
  final int minRankedMatches;

  @override
  List<Object?> get props => <Object?>[
    teamId,
    summary,
    ranking,
    topScorers,
    topAssists,
    weekendLeague,
    rivals,
    activity,
    minRankedMatches,
  ];
}
