import 'package:equatable/equatable.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_manager.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';

/// Critérios de busca de carta.
///
/// Os campos que a implementação de hoje ignora existem porque o contrato é
/// o que a Etapa 11 vai cumprir -- rating, liga, clube, nação e versão são os
/// filtros que uma fonte real oferece. Preferi declará-los agora e ignorá-los
/// a mudar a assinatura (e a UI junto) depois.
class PlayerCardQuery extends Equatable {
  const PlayerCardQuery({
    this.query,
    this.position,
    this.limit = 30,
    this.offset = 0,
    this.minRating,
    this.maxRating,
    this.leagueName,
    this.clubName,
    this.nationName,
    this.cardType,
    this.excludeCardIds = const <String>[],
  });

  final String? query;
  final String? position;
  final int limit;
  final int offset;
  final int? minRating;
  final int? maxRating;
  final String? leagueName;
  final String? clubName;
  final String? nationName;
  final String? cardType;

  /// Cartas já ocupando outro slot do squad atual -- nunca oferecidas de
  /// novo no picker (gameplay flows refresh, item 4).
  final List<String> excludeCardIds;

  PlayerCardQuery nextPage() => PlayerCardQuery(
    query: query,
    position: position,
    limit: limit,
    offset: offset + limit,
    minRating: minRating,
    maxRating: maxRating,
    leagueName: leagueName,
    clubName: clubName,
    nationName: nationName,
    cardType: cardType,
    excludeCardIds: excludeCardIds,
  );

  @override
  List<Object?> get props => <Object?>[
    query,
    position,
    limit,
    offset,
    minRating,
    maxRating,
    leagueName,
    clubName,
    nationName,
    cardType,
    excludeCardIds,
  ];
}

class PlayerCardPage extends Equatable {
  const PlayerCardPage({required this.items, required this.hasMore});

  final List<PlayerCard> items;
  final bool hasMore;

  @override
  List<Object?> get props => <Object?>[items, hasMore];
}

/// O contrato que a Etapa 11 precisa cumprir para o Squad Builder passar a
/// usar cartas reais. Nada acima desta interface sabe se os dados vieram de
/// FUT.GG, FUTBIN, FUTWIZ ou de um seed local -- por isso trocar a fonte não
/// deve exigir refazer nenhuma tela.
abstract interface class PlayerCardCatalogRepository {
  Future<PlayerCardPage> searchCards(PlayerCardQuery query);

  Future<PlayerCard?> getCard(String id);

  Future<List<FcManager>> searchManagers({String? nationId, String? query});

  Future<List<FcNation>> getNations();

  Future<List<FcLeague>> getLeagues();

  /// [leagueName] filtra pela liga, quando informado. Etapa 11: filtro de
  /// clube no picker de cartas.
  Future<List<FcClub>> getClubs({String? leagueName});

  /// Clubes com agregados (contagem de cartas + rating médio), para o card
  /// "Clubes" do Controle. Só clubes com pelo menos 1 carta ativa.
  Future<List<FcClubSummary>> getClubCatalogSummary({int limit = 12});
}
