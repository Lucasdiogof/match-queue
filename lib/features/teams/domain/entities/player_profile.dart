import 'package:equatable/equatable.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/formation.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';

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
    required this.rivalsWins,
    required this.rivalsLosses,
    this.rivalsDivision,
  });

  final String id;
  final String name;
  final String? rivalsDivision;
  final int rivalsWins;
  final int rivalsLosses;

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    rivalsDivision,
    rivalsWins,
    rivalsLosses,
  ];
}

/// Escalação principal completa -- mesma forma de formação/titulares que o
/// próprio Squad Builder usa, pro perfil desenhar o mesmo campinho (só
/// leitura, sem callback nenhum).
class PlayerProfileSquad extends Equatable {
  const PlayerProfileSquad({
    required this.name,
    required this.formation,
    required this.starters,
  });

  final String name;
  final FormationDefinition formation;

  /// slotCode -> carta.
  final Map<String, PlayerCard> starters;

  @override
  List<Object?> get props => <Object?>[name, formation, starters];
}

class PlayerProfileWeekendLeagueEntry extends Equatable {
  const PlayerProfileWeekendLeagueEntry({
    required this.eventId,
    required this.number,
    required this.startsAt,
    required this.wins,
    required this.losses,
    this.endsAt,
    this.season,
  });

  final String eventId;
  final int number;
  final String? season;
  final DateTime startsAt;
  final DateTime? endsAt;
  final int wins;
  final int losses;

  @override
  List<Object?> get props => <Object?>[
    eventId,
    number,
    season,
    startsAt,
    endsAt,
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
  final PlayerProfileSquad? squad;
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
