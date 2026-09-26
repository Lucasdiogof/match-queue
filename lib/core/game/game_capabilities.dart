import 'package:equatable/equatable.dart';

/// Quais funcionalidades do Match Queue este jogo oferece. Controla o que a
/// UI deve mostrar sem espalhar `if (game == 'ea_fc')` pela árvore de
/// widgets -- código de feature deve consultar `capabilities.market` etc.,
/// não a `GameFlavorKey` diretamente.
class GameCapabilities extends Equatable {
  const GameCapabilities({
    required this.teams,
    required this.matchmaking,
    required this.history,
    required this.squads,
    required this.cards,
    required this.market,
    required this.playStyles,
    required this.chemistry,
    required this.evolutions,
  });

  final bool teams;
  final bool matchmaking;
  final bool history;
  final bool squads;
  final bool cards;
  final bool market;
  final bool playStyles;
  final bool chemistry;
  final bool evolutions;

  @override
  List<Object?> get props => <Object?>[
    teams,
    matchmaking,
    history,
    squads,
    cards,
    market,
    playStyles,
    chemistry,
    evolutions,
  ];
}
