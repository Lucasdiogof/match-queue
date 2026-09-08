import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/fc_squads/data/models/fc_squad_model.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_manager.dart';
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

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error) {
      throw _errorMapper.map(error);
    }
  }
}
