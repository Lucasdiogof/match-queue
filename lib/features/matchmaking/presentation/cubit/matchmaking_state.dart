import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/my_matchmaking_status.dart';

enum MatchmakingStatus { loading, ready, failure }

/// Estado do canal de Realtime. Nao e estado do produto: mesmo
/// desconectado a tela continua util (o ultimo snapshot bom fica na tela,
/// as acoes continuam funcionando por HTTP e o refresh de seguranca
/// continua rodando).
enum MatchmakingConnection { connecting, connected, disconnected }

class MatchmakingState extends Equatable {
  const MatchmakingState({
    this.status = MatchmakingStatus.loading,
    this.snapshot,
    this.failure,
    this.isActionPending = false,
    this.isRefreshing = false,
    this.connection = MatchmakingConnection.connecting,
    this.promotionNonce = 0,
    this.serverOffset = Duration.zero,
  });

  final MatchmakingStatus status;
  final MyMatchmakingSnapshot? snapshot;
  final AppFailure? failure;
  final bool isActionPending;

  /// Releitura em andamento sobre um estado que ja esta na tela. Diferente
  /// de [MatchmakingStatus.loading], que e a primeira carga: refresh nunca
  /// desmonta a UI, no maximo acende um indicador discreto.
  final bool isRefreshing;

  final MatchmakingConnection connection;

  /// Incrementa quando o proprio usuario passa de QUEUED para SEARCHING --
  /// ou seja, quando chegou a vez dele. A UI escuta a mudanca deste numero
  /// para dar o feedback de "sua vez" uma unica vez por promocao, sem
  /// precisar comparar snapshots na camada de widget.
  final int promotionNonce;

  /// Diferenca entre o relogio do servidor e o do aparelho, calculada a
  /// cada snapshot novo. A UI soma isso a DateTime.now() para saber "que
  /// horas o servidor acha que sao agora" sem precisar consultar a rede a
  /// cada repaint do timer -- o Timer.periodic local so redesenha, nunca
  /// decide quando algo expira.
  final Duration serverOffset;

  DateTime estimatedServerNow() => DateTime.now().add(serverOffset);

  MatchmakingState copyWith({
    MatchmakingStatus? status,
    MyMatchmakingSnapshot? snapshot,
    AppFailure? failure,
    bool clearFailure = false,
    bool? isActionPending,
    bool? isRefreshing,
    MatchmakingConnection? connection,
    int? promotionNonce,
    Duration? serverOffset,
  }) => MatchmakingState(
    status: status ?? this.status,
    snapshot: snapshot ?? this.snapshot,
    failure: clearFailure ? null : (failure ?? this.failure),
    isActionPending: isActionPending ?? this.isActionPending,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    connection: connection ?? this.connection,
    promotionNonce: promotionNonce ?? this.promotionNonce,
    serverOffset: serverOffset ?? this.serverOffset,
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    snapshot,
    failure,
    isActionPending,
    isRefreshing,
    connection,
    promotionNonce,
    serverOffset,
  ];
}
