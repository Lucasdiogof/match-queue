import 'package:equatable/equatable.dart';

/// Metadado descritivo de um modo competitivo do jogo ativo (ex.: Champions,
/// Rivals). Não substitui o enum `GameMode` usado hoje pelo matchmaking --
/// é só a lista "quais modos este jogo tem" para uso futuro (ex.: Central
/// dinâmica por jogo). EA FC continua chaveado pelo `GameMode` existente.
class GameModeDescriptor extends Equatable {
  const GameModeDescriptor({
    required this.code,
    required this.name,
    required this.isRanked,
  });

  final String code;
  final String name;
  final bool isRanked;

  @override
  List<Object?> get props => <Object?>[code, name, isRanked];
}
