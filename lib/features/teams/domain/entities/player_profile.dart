import 'package:equatable/equatable.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account_stats.dart';
import 'package:fifa_queue/features/game/domain/entities/player_leaderboard_entry.dart';

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

/// Resumo esportivo do perfil publico -- Rivals all-time e ate 3 lideres de
/// gols/assistencias da conta. Nunca busca/historico operacional.
class PlayerProfileSportSummary extends Equatable {
  const PlayerProfileSportSummary({
    required this.rivals,
    required this.topScorers,
    required this.topAssists,
  });

  final FcAccountStats rivals;
  final List<PlayerLeaderboardEntry> topScorers;
  final List<PlayerLeaderboardEntry> topAssists;

  bool get hasAnyStats =>
      rivals.matchesCount > 0 || topScorers.isNotEmpty || topAssists.isNotEmpty;

  @override
  List<Object?> get props => <Object?>[rivals, topScorers, topAssists];
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
    this.sportSummary,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final List<PlayerProfileAccountCandidate> candidateAccounts;
  final bool needsAccountSelection;
  final PlayerProfileAccount? account;
  final PlayerProfileSquadSummary? squad;
  final List<PlayerProfileWeekendLeagueEntry> weekendLeagueHistory;
  final PlayerProfileSportSummary? sportSummary;

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
    sportSummary,
  ];
}
