import 'package:equatable/equatable.dart';

/// Atleta base (ex.: Mbappé), independente de qualquer carta/versão
/// específica. Uma carta ([PlayerCard]) pode ou não ter um [FcPlayer]
/// vinculado -- catálogo LOCAL/dev nunca tem, catálogo real vincula quando o
/// provider distingue jogador de carta.
///
/// Só carrega os campos que a RPC de busca de cartas devolve embutidos
/// (metadata leve, aditiva). Um contrato mais completo (histórico entre
/// versões, busca por jogador) fica para quando existir uma tela que precise
/// disso.
class FcPlayer extends Equatable {
  const FcPlayer({
    required this.id,
    required this.name,
    this.commonName,
    this.primaryPosition,
    this.imageUrl,
    this.nationName,
    this.clubName,
    this.leagueName,
  });

  final String id;
  final String name;
  final String? commonName;
  final String? primaryPosition;
  final String? imageUrl;
  final String? nationName;
  final String? clubName;
  final String? leagueName;

  String get displayName => commonName ?? name;

  @override
  List<Object?> get props => <Object?>[id, name, commonName, primaryPosition];
}
