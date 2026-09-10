import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/fc_squads/data/models/fc_squad_model.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_manager.dart'
    show FcClub, FcClubSummary, FcLeague, FcManager, FcNation;
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/fc_squads/domain/repositories/player_card_catalog_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lê o catálogo que vive no nosso banco. Hoje ele contém apenas as cartas
/// de desenvolvimento (provider LOCAL); na Etapa 11 passa a conter as reais,
/// e nada acima desta classe precisa mudar.
class SupabasePlayerCardCatalogRepository
    implements PlayerCardCatalogRepository {
  const SupabasePlayerCardCatalogRepository(this._client, this._errorMapper);

  final SupabaseClient _client;
  final SupabaseErrorMapper _errorMapper;

  @override
  Future<PlayerCardPage> searchCards(PlayerCardQuery query) => _guard(() async {
    final response = await _client.rpc<dynamic>(
      'search_fc_player_cards',
      params: <String, dynamic>{
        'p_query': query.query,
        'p_position': query.position,
        'p_limit': query.limit,
        'p_offset': query.offset,
        'p_min_rating': query.minRating,
        'p_max_rating': query.maxRating,
        'p_league_name': query.leagueName,
        'p_club_name': query.clubName,
        'p_nation_name': query.nationName,
        'p_card_type': query.cardType,
        'p_exclude_card_ids': query.excludeCardIds.isEmpty
            ? null
            : query.excludeCardIds,
        'p_club_id': query.clubId,
        'p_gender': query.gender,
        'p_playstyle': query.playstyle,
        'p_playstyle_plus_only': query.playstylePlusOnly,
      },
    );
    final json = Map<String, dynamic>.from(response as Map);
    final items = json['items'];
    return PlayerCardPage(
      items: <PlayerCard>[
        if (items is List)
          for (final item in items)
            if (item is Map)
              FcSquadModel.cardFromJson(Map<String, dynamic>.from(item)),
      ],
      hasMore: json['has_more'] as bool? ?? false,
    );
  });

  @override
  Future<PlayerCard?> getCard(String id) => _guard(() async {
    final rows = await _client
        .from('fc_player_cards')
        .select()
        .eq('id', id)
        .limit(1);
    if (rows.isEmpty) {
      return null;
    }
    return FcSquadModel.cardFromJson(Map<String, dynamic>.from(rows.first));
  });

  @override
  Future<List<FcManager>> searchManagers({String? nationId, String? query}) =>
      _guard(() async {
        final response = await _client.rpc<dynamic>(
          'search_fc_managers',
          params: <String, dynamic>{'p_nation_id': nationId, 'p_query': query},
        );
        return <FcManager>[
          if (response is List)
            for (final item in response)
              if (item is Map)
                ?FcSquadModel.managerFromJson(Map<String, dynamic>.from(item)),
        ];
      });

  @override
  Future<List<FcNation>> getNations() => _guard(() async {
    final rows = await _client
        .from('fc_nations')
        .select('id, name, flag_image_url')
        .order('name', ascending: true);
    return <FcNation>[
      for (final row in rows) ?FcSquadModel.nationFromJson(row),
    ];
  });

  @override
  Future<List<FcLeague>> getLeagues() => _guard(() async {
    final rows = await _client
        .from('fc_leagues')
        .select('id, name, logo_image_url')
        .order('name', ascending: true);
    return <FcLeague>[
      for (final row in rows) ?FcSquadModel.leagueFromJson(row),
    ];
  });

  @override
  Future<List<FcClub>> getClubs({String? leagueName}) => _guard(() async {
    var builder = _client
        .from('fc_clubs')
        .select('id, name, league_id, logo_image_url');
    if (leagueName != null) {
      final leagueRows = await _client
          .from('fc_leagues')
          .select('id')
          .eq('name', leagueName)
          .limit(1);
      if (leagueRows.isEmpty) {
        return const <FcClub>[];
      }
      builder = builder.eq('league_id', leagueRows.first['id'] as Object);
    }
    final rows = await builder.order('name', ascending: true);
    return <FcClub>[for (final row in rows) ?FcSquadModel.clubFromJson(row)];
  });

  @override
  Future<List<FcClubSummary>> getClubCatalogSummary({int limit = 12}) =>
      _guard(() async {
        final response = await _client.rpc<dynamic>(
          'get_fc_club_catalog_summary',
          params: <String, dynamic>{'p_limit': limit},
        );
        return <FcClubSummary>[
          if (response is List)
            for (final entry in response)
              if (entry is Map)
                _clubSummaryFromJson(Map<String, dynamic>.from(entry)),
        ];
      });

  FcClubSummary _clubSummaryFromJson(Map<String, dynamic> json) =>
      FcClubSummary(
        clubId: '${json['club_id']}',
        name: '${json['name']}',
        logoImageUrl: json['logo_image_url'] as String?,
        leagueName: json['league_name'] as String?,
        cardCount: json['card_count'] is int ? json['card_count'] as int : 0,
        averageRating: json['average_rating'] is int
            ? json['average_rating'] as int
            : (json['average_rating'] as num?)?.round(),
      );

  static FcClubSummary _clubFromListJson(Map<String, dynamic> json) =>
      FcClubSummary(
        clubId: '${json['id']}',
        name: '${json['name']}',
        logoImageUrl: json['logo_image_url'] as String?,
        leagueName: json['league_name'] as String?,
        gender: json['gender'] as String?,
        cardCount: json['cards_count'] is int
            ? json['cards_count'] as int
            : ((json['cards_count'] as num?)?.round() ?? 0),
        averageRating: (json['average_rating'] as num?)?.round(),
        topRating: (json['top_rating'] as num?)?.round(),
      );

  @override
  Future<FcClubPage> listClubs({
    String? query,
    String? gender,
    int limit = 30,
    int offset = 0,
  }) => _guard(() async {
    final response = await _client.rpc<dynamic>(
      'list_fc_clubs',
      params: <String, dynamic>{
        'p_query': query,
        'p_gender': gender,
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    final json = Map<String, dynamic>.from(response as Map);
    final items = json['items'];
    return FcClubPage(
      items: <FcClubSummary>[
        if (items is List)
          for (final item in items)
            if (item is Map) _clubFromListJson(Map<String, dynamic>.from(item)),
      ],
      hasMore: json['has_more'] == true,
    );
  });

  @override
  Future<FcClubSummary> getClubSummary(String clubId) => _guard(() async {
    final response = await _client.rpc<dynamic>(
      'get_fc_club_summary',
      params: <String, dynamic>{'p_club_id': clubId},
    );
    return _clubFromListJson(Map<String, dynamic>.from(response as Map));
  });

  @override
  Future<List<FcPlaystyleSummary>> getPlaystyleSummary() => _guard(() async {
    final response = await _client.rpc<dynamic>('get_fc_playstyle_summary');
    return <FcPlaystyleSummary>[
      if (response is List)
        for (final entry in response)
          if (entry is Map)
            FcPlaystyleSummary(
              style: '${entry['style']}',
              cardCount: entry['card_count'] is int
                  ? entry['card_count'] as int
                  : 0,
              plusCardCount: entry['plus_card_count'] is int
                  ? entry['plus_card_count'] as int
                  : 0,
            ),
    ];
  });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error) {
      throw _errorMapper.map(error);
    }
  }
}
