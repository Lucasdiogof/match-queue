import 'package:equatable/equatable.dart';

/// Uma linha de artilharia/assistencias agregada por jogador (gols e
/// assistencias somados de game_match_player_stats). [playerKey] e o
/// card_id quando disponivel, senao a snapshot_player_key -- so serve pra
/// desduplicar linhas no cliente, nunca e mostrado na UI.
class PlayerLeaderboardEntry extends Equatable {
  const PlayerLeaderboardEntry({
    required this.playerKey,
    required this.playerName,
    required this.goals,
    required this.assists,
  });

  final String playerKey;
  final String playerName;
  final int goals;
  final int assists;

  static PlayerLeaderboardEntry fromJson(Map<String, dynamic> json) =>
      PlayerLeaderboardEntry(
        playerKey: '${json['player_key']}',
        playerName: '${json['player_name']}',
        goals: json['goals'] as int? ?? 0,
        assists: json['assists'] as int? ?? 0,
      );

  static List<PlayerLeaderboardEntry> listFromJson(Object? json) {
    if (json is! List) {
      return const <PlayerLeaderboardEntry>[];
    }
    return json
        .whereType<Map<String, dynamic>>()
        .map(PlayerLeaderboardEntry.fromJson)
        .toList(growable: false);
  }

  @override
  List<Object?> get props => <Object?>[playerKey, playerName, goals, assists];
}
