import 'package:equatable/equatable.dart';

/// Uma edicao de Champions no historico de uma conta -- generico o bastante
/// pra vir do perfil de um companheiro de time OU de um perfil publico, que
/// trazem os mesmos campos por RPCs diferentes.
class WeekendLeagueHistoryEntry extends Equatable {
  const WeekendLeagueHistoryEntry({
    required this.eventId,
    required this.number,
    required this.startsAt,
    required this.wins,
    required this.losses,
    this.endsAt,
    this.season,
  });

  final String eventId;
  final int number;
  final String? season;
  final DateTime startsAt;
  final DateTime? endsAt;
  final int wins;
  final int losses;

  @override
  List<Object?> get props => <Object?>[
    eventId,
    number,
    season,
    startsAt,
    endsAt,
    wins,
    losses,
  ];
}
