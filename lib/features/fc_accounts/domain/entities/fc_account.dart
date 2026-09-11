import 'package:equatable/equatable.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/rivals_division.dart';

/// Elenco (conta de Ultimate Team) do usuário -- nunca "conta EA" na UI.
/// Pertence ao usuário, não ao time; [teamIds] é o vínculo N:N com os times
/// que este elenco representa.
class FcAccount extends Equatable {
  const FcAccount({
    required this.id,
    required this.name,
    required this.isActive,
    required this.teamIds,
    this.rivalsDivision,
    this.weekendLeagueComputedWins = 0,
    this.weekendLeagueComputedLosses = 0,
    this.weekendLeagueManualWins,
    this.weekendLeagueManualLosses,
    this.rivalsWins = 0,
    this.rivalsLosses = 0,
  });

  final String id;
  final String name;
  final bool isActive;
  final List<String> teamIds;
  final RivalsDivision? rivalsDivision;
  final int weekendLeagueComputedWins;
  final int weekendLeagueComputedLosses;
  final int? weekendLeagueManualWins;
  final int? weekendLeagueManualLosses;

  /// Contador manual (+1 vitoria / +1 derrota) de Division Rivals -- unica
  /// fonte hoje, nao ha mais calculo a partir de partida real na UI.
  final int rivalsWins;
  final int rivalsLosses;

  bool get hasWeekendLeagueManualOverride => weekendLeagueManualWins != null;

  /// O contador manual (+1 vitoria / +1 derrota) e a UNICA fonte que a UI
  /// mostra hoje -- nunca mais cai pro computado de partida real.
  /// [weekendLeagueComputedWins]/[weekendLeagueComputedLosses] continuam
  /// existindo no servidor (RPCs antigas), so nao aparecem mais aqui.
  (int wins, int losses) get weekendLeagueRecord =>
      (weekendLeagueManualWins ?? 0, weekendLeagueManualLosses ?? 0);

  bool isLinkedTo(String teamId) => teamIds.contains(teamId);

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    isActive,
    teamIds,
    rivalsDivision,
    weekendLeagueComputedWins,
    weekendLeagueComputedLosses,
    weekendLeagueManualWins,
    weekendLeagueManualLosses,
    rivalsWins,
    rivalsLosses,
  ];
}
