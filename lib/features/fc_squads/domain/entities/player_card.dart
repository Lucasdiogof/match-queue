import 'package:equatable/equatable.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_player.dart';

/// Carta de jogador, sempre com identidade NOSSA.
///
/// [provider] e [providerCardId] guardam a origem (LOCAL hoje; FUT_GG,
/// FUTBIN, FUTWIZ depois) sem que nada no app dependa dela: trocar de fonte
/// muda quem popula o catálogo, nunca quem o lê.
///
/// [fcPlayerId]/[player] apontam para o atleta base ([FcPlayer]) desta
/// carta, quando o catálogo distingue jogador de versão -- nulos para
/// catálogo LOCAL/dev e para qualquer carta cujo provider não tenha
/// declarado a identidade do jogador. A carta continua o card-centric
/// visualmente: isto é metadata adicional, nunca substitui os campos de
/// carta já existentes.
class PlayerCard extends Equatable {
  const PlayerCard({
    required this.id,
    required this.provider,
    required this.playerName,
    required this.rating,
    required this.primaryPosition,
    required this.alternativePositions,
    this.commonName,
    this.fcPlayerId,
    this.player,
    this.pace,
    this.shooting,
    this.passing,
    this.dribbling,
    this.defending,
    this.physical,
    this.playerImageUrl,
    this.cardImageUrl,
    this.clubName,
    this.leagueName,
    this.nationName,
    this.cardType,
    this.gameVersion = 'FC27',
    this.gkDiving,
    this.gkHandling,
    this.gkKicking,
    this.gkReflexes,
    this.gkSpeed,
    this.gkPositioning,
    this.skillMoves,
    this.weakFoot,
    this.playstyles = const <String>[],
    this.heightCm,
    this.preferredFoot,
    this.playerRoles = const <String>[],
    this.rarity,
  });

  final String id;
  final String provider;
  final String gameVersion;
  final String playerName;
  final String? commonName;
  final String? fcPlayerId;
  final FcPlayer? player;
  final int rating;
  final String primaryPosition;
  final List<String> alternativePositions;
  final int? pace;
  final int? shooting;
  final int? passing;
  final int? dribbling;
  final int? defending;
  final int? physical;
  final int? gkDiving;
  final int? gkHandling;
  final int? gkKicking;
  final int? gkReflexes;
  final int? gkSpeed;
  final int? gkPositioning;
  final int? skillMoves;
  final int? weakFoot;
  final List<String> playstyles;
  final int? heightCm;
  final String? preferredFoot;
  final List<String> playerRoles;
  final String? rarity;
  final String? playerImageUrl;
  final String? cardImageUrl;
  final String? clubName;
  final String? leagueName;
  final String? nationName;
  final String? cardType;

  bool get isGoalkeeper => primaryPosition == 'GK';

  String get displayName => commonName ?? playerName;

  /// Química não existe nesta etapa: elegibilidade é só a posição primária
  /// mais as alternativas da carta. O backend valida a mesma regra.
  bool canPlayIn(String positionCode) =>
      primaryPosition == positionCode ||
      alternativePositions.contains(positionCode);

  /// Iniciais para o placeholder visual enquanto não há arte de carta.
  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return _take(parts.first, 2).toUpperCase();
    }
    return '${_take(parts.first, 1)}${_take(parts.last, 1)}'.toUpperCase();
  }

  static String _take(String value, int count) =>
      String.fromCharCodes(value.runes.take(count));

  @override
  List<Object?> get props => <Object?>[id, provider, rating, primaryPosition];
}
