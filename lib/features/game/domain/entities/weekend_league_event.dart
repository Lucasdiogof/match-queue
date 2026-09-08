import 'package:equatable/equatable.dart';

/// Uma campanha de Weekend League. Janela definida no banco (nunca calculada
/// no cliente) porque a duração real de cada FUT Champions varia por season.
class WeekendLeagueEvent extends Equatable {
  const WeekendLeagueEvent({
    required this.id,
    required this.number,
    required this.startsAt,
    required this.endsAt,
    this.season,
  });

  final String id;
  final int number;
  final String? season;
  final DateTime startsAt;
  final DateTime endsAt;

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startsAt) && now.isBefore(endsAt);
  }

  @override
  List<Object?> get props => <Object?>[id, number, season, startsAt, endsAt];
}

/// Vitórias/derrotas computadas das partidas FINISHED do evento -- nunca
/// soma o override manual (Etapa 9, ligado ao Elenco/Conta).
class WeekendLeagueRecord extends Equatable {
  const WeekendLeagueRecord({required this.wins, required this.losses});

  final int wins;
  final int losses;

  @override
  List<Object?> get props => <Object?>[wins, losses];
}
