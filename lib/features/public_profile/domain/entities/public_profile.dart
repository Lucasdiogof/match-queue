import 'package:equatable/equatable.dart';

/// Agregado publico de partidas (W/L/gols) de um recorte -- mesmo formato
/// que _fc_account_match_aggregate devolve, so que ja whitelisted pela RPC
/// publica antes de chegar aqui.
class PublicMatchAggregate extends Equatable {
  const PublicMatchAggregate({
    required this.matchesCount,
    required this.wins,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDiff,
  });

  static const PublicMatchAggregate empty = PublicMatchAggregate(
    matchesCount: 0,
    wins: 0,
    losses: 0,
    goalsFor: 0,
    goalsAgainst: 0,
    goalDiff: 0,
  );

  final int matchesCount;
  final int wins;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDiff;

  @override
  List<Object?> get props => <Object?>[
    matchesCount,
    wins,
    losses,
    goalsFor,
    goalsAgainst,
    goalDiff,
  ];
}

/// Um titular no card visual publico. Nunca carrega id interno nem stats
/// detalhados de carta -- so o que o card precisa mostrar.
class PublicSquadStarter extends Equatable {
  const PublicSquadStarter({
    required this.slotCode,
    required this.playerName,
    required this.rating,
    required this.position,
    required this.chemistry,
    this.imageUrl,
    this.cardType,
  });

  final String slotCode;
  final String playerName;
  final int rating;
  final String position;
  final int chemistry;
  final String? imageUrl;
  final String? cardType;

  @override
  List<Object?> get props => <Object?>[
    slotCode,
    playerName,
    rating,
    position,
    chemistry,
    imageUrl,
    cardType,
  ];
}

class PublicSquad extends Equatable {
  const PublicSquad({
    required this.name,
    required this.formationCode,
    required this.formationDisplayName,
    required this.chemistry,
    required this.starters,
    this.overall,
    this.chemistryRuleVersion,
  });

  final String name;
  final String formationCode;
  final String formationDisplayName;
  final int? overall;
  final int chemistry;
  final String? chemistryRuleVersion;
  final List<PublicSquadStarter> starters;

  @override
  List<Object?> get props => <Object?>[
    name,
    formationCode,
    formationDisplayName,
    overall,
    chemistry,
    chemistryRuleVersion,
    starters,
  ];
}

/// Payload publico de `get_public_profile`. [found] falso cobre TANTO "nao
/// existe" quanto "existe mas esta desativado" -- de proposito, a UI nunca
/// deve tentar distinguir os dois (item 29).
class PublicProfile extends Equatable {
  const PublicProfile({
    required this.found,
    this.displayName,
    this.avatarUrl,
    this.accountName,
    this.rivalsDivision,
    this.stats,
    this.weekendLeague,
    this.rivals,
    this.squad,
  });

  static const PublicProfile notFound = PublicProfile(found: false);

  final bool found;
  final String? displayName;
  final String? avatarUrl;
  final String? accountName;
  final String? rivalsDivision;
  final PublicMatchAggregate? stats;
  final PublicMatchAggregate? weekendLeague;
  final PublicMatchAggregate? rivals;
  final PublicSquad? squad;

  bool get hasAccount => accountName != null;

  @override
  List<Object?> get props => <Object?>[
    found,
    displayName,
    avatarUrl,
    accountName,
    rivalsDivision,
    stats,
    weekendLeague,
    rivals,
    squad,
  ];
}
