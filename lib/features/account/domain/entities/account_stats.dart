import 'package:equatable/equatable.dart';

/// Record manual (+1 vitoria / +1 derrota) do usuario -- unica fonte de
/// vitorias/derrotas hoje, nao ha placar/resultado por partida no backend.
class ManualRecord extends Equatable {
  const ManualRecord({required this.wins, required this.losses});

  final int wins;
  final int losses;

  static ManualRecord? fromJson(Object? json) {
    if (json is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(json);
    return ManualRecord(
      wins: map['wins'] as int? ?? 0,
      losses: map['losses'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => <Object?>[wins, losses];
}

/// Record manual de uma campanha de Weekend League do usuario.
class WeekendLeagueAccountStats extends Equatable {
  const WeekendLeagueAccountStats({this.manual});

  final ManualRecord? manual;

  static WeekendLeagueAccountStats fromJson(Map<String, dynamic> json) =>
      WeekendLeagueAccountStats(manual: ManualRecord.fromJson(json['manual']));

  @override
  List<Object?> get props => <Object?>[manual];
}

/// Division Rivals do usuario -- all-time nesta etapa (sem season/semana
/// modelada ainda, simplificacao consciente).
class RivalsAccountStats extends Equatable {
  const RivalsAccountStats({required this.manual});

  final ManualRecord manual;

  static RivalsAccountStats fromJson(Map<String, dynamic> json) =>
      RivalsAccountStats(
        manual:
            ManualRecord.fromJson(json['manual']) ??
            const ManualRecord(wins: 0, losses: 0),
      );

  @override
  List<Object?> get props => <Object?>[manual];
}
