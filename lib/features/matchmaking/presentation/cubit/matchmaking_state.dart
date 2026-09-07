import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/matchmaking_snapshot.dart';

enum MatchmakingStatus { loading, ready, failure }

class MatchmakingState extends Equatable {
  const MatchmakingState({
    this.status = MatchmakingStatus.loading,
    this.snapshot,
    this.failure,
    this.isActionPending = false,
    this.serverOffset = Duration.zero,
  });

  final MatchmakingStatus status;
  final MatchmakingSnapshot? snapshot;
  final AppFailure? failure;
  final bool isActionPending;

  /// Diferenca entre o relogio do servidor e o do aparelho, calculada a
  /// cada snapshot novo. A UI soma isso a DateTime.now() para saber "que
  /// horas o servidor acha que sao agora" sem precisar consultar a rede a
  /// cada repaint do timer -- o Timer.periodic local so redesenha, nunca
  /// decide quando algo expira.
  final Duration serverOffset;

  DateTime estimatedServerNow() => DateTime.now().add(serverOffset);

  MatchmakingState copyWith({
    MatchmakingStatus? status,
    MatchmakingSnapshot? snapshot,
    AppFailure? failure,
    bool clearFailure = false,
    bool? isActionPending,
    Duration? serverOffset,
  }) => MatchmakingState(
    status: status ?? this.status,
    snapshot: snapshot ?? this.snapshot,
    failure: clearFailure ? null : (failure ?? this.failure),
    isActionPending: isActionPending ?? this.isActionPending,
    serverOffset: serverOffset ?? this.serverOffset,
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    snapshot,
    failure,
    isActionPending,
    serverOffset,
  ];
}
