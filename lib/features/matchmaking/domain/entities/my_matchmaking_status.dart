import 'package:equatable/equatable.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';

enum MyMatchmakingStatus { searching, queued, none }

/// Quem esta buscando pelo time agora, quando nao sou eu.
class BlockingSearch extends Equatable {
  const BlockingSearch({
    required this.userId,
    required this.displayName,
    required this.expiresAt,
    this.avatarUrl,
    this.gameMode,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final DateTime expiresAt;
  final GameMode? gameMode;

  @override
  List<Object?> get props => <Object?>[
    userId,
    displayName,
    avatarUrl,
    expiresAt,
    gameMode,
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

/// Uma outra busca ATIVA da mesma Conta FC, num time diferente do que esta
/// tela mostra agora -- o lock global impede a mesma conta de buscar em
/// dois times, e a UI precisa explicar isso em vez de so esconder o botao
/// (item 9 do pedido).
class SearchingElsewhere extends Equatable {
  const SearchingElsewhere({
    required this.teamId,
    required this.teamName,
    required this.expiresAt,
  });

  final String teamId;
  final String teamName;
  final DateTime expiresAt;

  @override
  List<Object?> get props => <Object?>[teamId, teamName, expiresAt];
}

/// Uma linha da fila VISIVEL de um time (item 2/25: mostrar quem esta
/// esperando, nao so "sua posicao").
class QueueEntry extends Equatable {
  const QueueEntry({
    required this.position,
    required this.userId,
    required this.displayName,
    required this.isMe,
    this.avatarUrl,
    this.gameMode,
  });

  final int position;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final GameMode? gameMode;
  final bool isMe;

  @override
  List<Object?> get props => <Object?>[
    position,
    userId,
    displayName,
    avatarUrl,
    gameMode,
    isMe,
  ];
}

/// Read model de usuario + TIME (fila real por time): reflete
/// get_my_matchmaking_status(team_id, game_mode). Cada Time tem sua
/// propria fila e seu proprio estado -- o mesmo usuario pode estar em 1o
/// lugar no Time A e 3o no Time B ao mesmo tempo, mas so pode estar
/// SEARCHING em UM time por vez (lock global por usuario).
class MyMatchmakingSnapshot extends Equatable {
  const MyMatchmakingSnapshot({
    required this.userId,
    required this.teamId,
    required this.myStatus,
    required this.serverNow,
    this.searchDurationSeconds,
    this.searching,
    this.myPosition,
    this.blockingSearch,
    this.searchingElsewhere,
    this.queue = const <QueueEntry>[],
  });

  final String userId;
  final String teamId;

  final int? searchDurationSeconds;
  final MySearching? searching;
  final MyMatchmakingStatus myStatus;
  final int? myPosition;
  final BlockingSearch? blockingSearch;
  final SearchingElsewhere? searchingElsewhere;
  final List<QueueEntry> queue;
  final DateTime serverNow;

  bool get isSearchingByMe => myStatus == MyMatchmakingStatus.searching;

  bool get isQueuedByMe => myStatus == MyMatchmakingStatus.queued;

  bool get isIdle => myStatus == MyMatchmakingStatus.none;

  bool get isBusyElsewhere => searchingElsewhere != null;

  @override
  List<Object?> get props => <Object?>[
    userId,
    teamId,
    searchDurationSeconds,
    searching,
    myStatus,
    myPosition,
    blockingSearch,
    searchingElsewhere,
    queue,
    serverNow,
  ];
}
