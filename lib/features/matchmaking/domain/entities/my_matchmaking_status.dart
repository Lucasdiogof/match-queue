import 'package:equatable/equatable.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';

enum MyMatchmakingStatus { searching, queued, none }

/// Quem esta ocupando um dos times vinculados a minha conta agora -- explica
/// por que estou na fila mesmo sem ver a fila inteira (a conta so enxerga o
/// que toca os PROPRIOS times, nunca a fila de outra conta sem overlap).
class BlockingSearch extends Equatable {
  const BlockingSearch({
    required this.userId,
    required this.displayName,
    required this.expiresAt,
    this.avatarUrl,
    this.fcAccountName,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final DateTime expiresAt;
  final String? fcAccountName;

  @override
  List<Object?> get props => <Object?>[
    userId,
    displayName,
    avatarUrl,
    expiresAt,
    fcAccountName,
  ];
}

class MySearching extends Equatable {
  const MySearching({
    required this.sessionId,
    required this.startedAt,
    required this.expiresAt,
    this.gameMode,
    this.fcSquadId,
    this.fcSquadName,
  });

  final String sessionId;
  final DateTime startedAt;
  final DateTime expiresAt;
  final GameMode? gameMode;
  final String? fcSquadId;
  final String? fcSquadName;

  @override
  List<Object?> get props => <Object?>[
    sessionId,
    startedAt,
    expiresAt,
    gameMode,
    fcSquadId,
    fcSquadName,
  ];
}

/// Read model centrado em CONTA (nao em time) que alimenta a tela Jogar
/// desde a Etapa 11 -- espelha get_my_matchmaking_status. Uma conta pode
/// estar ligada a varios times; buscar ocupa todos eles de uma vez, entao a
/// UI nunca mais escolhe um time para mostrar estado.
class MyMatchmakingSnapshot extends Equatable {
  const MyMatchmakingSnapshot({
    required this.fcAccountId,
    required this.linkedTeamIds,
    required this.myStatus,
    required this.serverNow,
    this.searchDurationSeconds,
    this.searching,
    this.myPosition,
    this.blockingSearch,
  });

  final String fcAccountId;
  final List<String> linkedTeamIds;
  final int? searchDurationSeconds;
  final MySearching? searching;
  final MyMatchmakingStatus myStatus;
  final int? myPosition;
  final BlockingSearch? blockingSearch;
  final DateTime serverNow;

  bool get isSearchingByMe => myStatus == MyMatchmakingStatus.searching;

  bool get isQueuedByMe => myStatus == MyMatchmakingStatus.queued;

  bool get isIdle => myStatus == MyMatchmakingStatus.none;

  bool get hasNoLinkedTeam => linkedTeamIds.isEmpty;

  @override
  List<Object?> get props => <Object?>[
    fcAccountId,
    linkedTeamIds,
    searchDurationSeconds,
    searching,
    myStatus,
    myPosition,
    blockingSearch,
    serverNow,
  ];
}
