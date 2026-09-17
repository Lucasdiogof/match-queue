import 'package:equatable/equatable.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/formation.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';

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

/// Perfil publico de um membro do time. So o que qualquer companheiro de
/// time pode ver -- nunca historico de busca, nunca preferencia privada.
class PlayerProfile extends Equatable {
  const PlayerProfile({
    required this.userId,
    required this.displayName,
    required this.rivalsWins,
    required this.rivalsLosses,
    required this.weekendLeagueHistory,
    this.avatarUrl,
    this.rivalsDivision,
    this.squad,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String? rivalsDivision;
  final int rivalsWins;
  final int rivalsLosses;
  final PlayerProfileSquad? squad;
  final List<PlayerProfileWeekendLeagueEntry> weekendLeagueHistory;

  @override
  List<Object?> get props => <Object?>[
    userId,
    displayName,
    avatarUrl,
    rivalsDivision,
    rivalsWins,
    rivalsLosses,
    squad,
    weekendLeagueHistory,
  ];
}
