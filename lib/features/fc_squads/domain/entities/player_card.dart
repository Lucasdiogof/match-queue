import 'package:equatable/equatable.dart';

/// Carta de jogador, sempre com identidade NOSSA.
///
/// [provider] e [providerCardId] guardam a origem (LOCAL hoje; FUT_GG,
/// FUTBIN, FUTWIZ depois) sem que nada no app dependa dela: trocar de fonte
/// muda quem popula o catálogo, nunca quem o lê.
class PlayerCard extends Equatable {
  const PlayerCard({
    required this.id,
    required this.provider,
    required this.playerName,
    required this.rating,
    required this.primaryPosition,
    required this.alternativePositions,
    this.commonName,
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
  });

  final String id;
  final String provider;
  final String playerName;
  final String? commonName;
  final int rating;
  final String primaryPosition;
  final List<String> alternativePositions;
  final int? pace;
  final int? shooting;
  final int? passing;
  final int? dribbling;
  final int? defending;
  final int? physical;
  final String? playerImageUrl;
  final String? cardImageUrl;
  final String? clubName;
  final String? leagueName;
  final String? nationName;
  final String? cardType;

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
