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

  bool get hasWeekendLeagueManualOverride => weekendLeagueManualWins != null;

  /// O record "principal" a mostrar: manual quando existe (mais confiável,
  /// é o que o usuário disse que aconteceu), senão o computado das partidas.
  (int wins, int losses) get weekendLeagueRecord =>
      hasWeekendLeagueManualOverride
      ? (weekendLeagueManualWins!, weekendLeagueManualLosses!)
      : (weekendLeagueComputedWins, weekendLeagueComputedLosses);

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
  ];
}
