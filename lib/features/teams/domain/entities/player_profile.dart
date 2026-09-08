import 'package:equatable/equatable.dart';

/// Perfil publico de um membro do time (Etapa 11, Parte B). So o que
/// qualquer companheiro de time pode ver -- nunca historico de busca, nunca
/// outras contas do usuario.
class PlayerProfileAccountCandidate extends Equatable {
  const PlayerProfileAccountCandidate({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => <Object?>[id, name];
}

class PlayerProfileAccount extends Equatable {
  const PlayerProfileAccount({
    required this.id,
    required this.name,
    this.rivalsDivision,
  });

  final String id;
  final String name;
  final String? rivalsDivision;

  @override
  List<Object?> get props => <Object?>[id, name, rivalsDivision];
}

class PlayerProfileSquadSummary extends Equatable {
  const PlayerProfileSquadSummary({
    required this.id,
    required this.name,
    required this.formationCode,
    required this.startingCount,
    required this.startingTotal,
  });

  final String id;
  final String name;
  final String formationCode;
  final int startingCount;
  final int startingTotal;

  double get completeness =>
      startingTotal == 0 ? 0 : startingCount / startingTotal;

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    formationCode,
    startingCount,
    startingTotal,
  ];
}

class PlayerProfileWeekendLeagueEntry extends Equatable {
  const PlayerProfileWeekendLeagueEntry({
    required this.eventId,
    required this.number,
    required this.season,
    required this.startsAt,
    required this.wins,
    required this.losses,
  });

  final String eventId;
  final int number;
  final int season;
  final DateTime startsAt;
  final int wins;
  final int losses;

  @override
  List<Object?> get props => <Object?>[
    eventId,
    number,
    season,
    startsAt,
    wins,
    losses,
  ];
}

class PlayerProfile extends Equatable {
  const PlayerProfile({
    required this.userId,
    required this.displayName,
    required this.candidateAccounts,
    required this.needsAccountSelection,
    required this.weekendLeagueHistory,
    this.avatarUrl,
    this.account,
    this.squad,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final List<PlayerProfileAccountCandidate> candidateAccounts;
  final bool needsAccountSelection;
  final PlayerProfileAccount? account;
  final PlayerProfileSquadSummary? squad;
  final List<PlayerProfileWeekendLeagueEntry> weekendLeagueHistory;

  @override
  List<Object?> get props => <Object?>[
    userId,
    displayName,
    avatarUrl,
    candidateAccounts,
    needsAccountSelection,
    account,
    squad,
    weekendLeagueHistory,
  ];
}
