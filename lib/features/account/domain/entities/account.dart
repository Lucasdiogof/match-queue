import 'package:equatable/equatable.dart';
import 'package:fifa_queue/features/account/domain/entities/platform.dart';
import 'package:fifa_queue/features/account/domain/entities/rivals_division.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_event.dart';

/// A conta autenticada. 1 login = 1 usuario do Match Queue -- tudo que antes
/// vivia num "Perfil" separado (nome, plataformas, squad, times, Rivals,
/// Champions) pertence direto aqui.
class Account extends Equatable {
  const Account({
    required this.id,
    required this.displayName,
    required this.createdAt,
    required this.updatedAt,
    this.avatarUrl,
    this.locale,
    this.platforms = const <Platform>[],
    this.rivalsDivision,
    this.teamIds = const <String>[],
    this.weekendLeagueManualWins,
    this.weekendLeagueManualLosses,
    this.rivalsWins = 0,
    this.rivalsLosses = 0,
    this.weekendLeagueEvent,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? locale;
  final List<Platform> platforms;
  final RivalsDivision? rivalsDivision;
  final List<String> teamIds;
  final int? weekendLeagueManualWins;
  final int? weekendLeagueManualLosses;
  final int rivalsWins;
  final int rivalsLosses;
  final WeekendLeagueEvent? weekendLeagueEvent;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasWeekendLeagueManualOverride => weekendLeagueManualWins != null;

  (int wins, int losses) get weekendLeagueRecord =>
      (weekendLeagueManualWins ?? 0, weekendLeagueManualLosses ?? 0);

  bool isLinkedTo(String teamId) => teamIds.contains(teamId);

  Account copyWith({String? displayName, String? avatarUrl, String? locale}) =>
      Account(
        id: id,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        locale: locale ?? this.locale,
        platforms: platforms,
        rivalsDivision: rivalsDivision,
        teamIds: teamIds,
        weekendLeagueManualWins: weekendLeagueManualWins,
        weekendLeagueManualLosses: weekendLeagueManualLosses,
        rivalsWins: rivalsWins,
        rivalsLosses: rivalsLosses,
        weekendLeagueEvent: weekendLeagueEvent,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  @override
  List<Object?> get props => <Object?>[
    id,
    displayName,
    avatarUrl,
    locale,
    platforms,
    rivalsDivision,
    teamIds,
    weekendLeagueManualWins,
    weekendLeagueManualLosses,
    rivalsWins,
    rivalsLosses,
    weekendLeagueEvent,
    createdAt,
    updatedAt,
  ];
}
