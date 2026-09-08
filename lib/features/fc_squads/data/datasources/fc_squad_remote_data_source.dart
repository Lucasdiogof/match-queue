import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class FcSquadRemoteDataSource {
  Future<List<Map<String, dynamic>>> listFormations();

  Future<Object?> listSquads(String fcAccountId);

  Future<Map<String, dynamic>> getBuilder(String squadId);

  Future<Map<String, dynamic>> createSquad({
    required String fcAccountId,
    required String name,
    required String formationCode,
  });

  Future<Map<String, dynamic>> renameSquad({
    required String squadId,
    required String name,
  });

  Future<Map<String, dynamic>> setFormation({
    required String squadId,
    required String formationCode,
  });

  Future<Map<String, dynamic>> setDefault(String squadId);

  Future<void> archiveSquad(String squadId);

  Future<Map<String, dynamic>> setSlot({
    required String squadId,
    required String slotType,
    required String slotCode,
    required String playerCardId,
  });

  Future<Map<String, dynamic>> clearSlot({
    required String squadId,
    required String slotType,
    required String slotCode,
  });

  Future<Map<String, dynamic>> swapSlots({
    required String squadId,
    required String fromType,
    required String fromCode,
    required String toType,
    required String toCode,
  });

  Future<Map<String, dynamic>> setManager({
    required String squadId,
    String? managerId,
    String? managerLeagueId,
  });
}

class SupabaseFcSquadRemoteDataSource implements FcSquadRemoteDataSource {
  const SupabaseFcSquadRemoteDataSource(this._client);

  final SupabaseClient _client;

  /// O catálogo é global e read-only, então sai por select direto em vez de
  /// RPC -- não há nada a validar por chamador.
  @override
  Future<List<Map<String, dynamic>>> listFormations() async {
    final formations = await _client
        .from('fc_formations')
        .select('code, display_name, sort_order')
        .eq('is_active', true)
        // ascending explícito: o default do postgrest-dart é DESCENDENTE.
        .order('sort_order', ascending: true);

    final slots = await _client
        .from('fc_formation_slots')
        .select('formation_code, slot_code, position_code, x, y, sort_order')
        .order('formation_code', ascending: true)
        .order('sort_order', ascending: true);

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final row in slots) {
      final slot = Map<String, dynamic>.from(row);
      grouped.putIfAbsent('${slot['formation_code']}', () => []).add(slot);
    }

    return <Map<String, dynamic>>[
      for (final row in formations)
        <String, dynamic>{
          ...Map<String, dynamic>.from(row),
          'slots': grouped['${row['code']}'] ?? const <Map<String, dynamic>>[],
        },
    ];
  }

  @override
  Future<Object?> listSquads(String fcAccountId) => _client.rpc<dynamic>(
    'list_fc_squads',
    params: <String, dynamic>{'p_fc_account_id': fcAccountId},
  );

  @override
  Future<Map<String, dynamic>> getBuilder(String squadId) =>
      _map('get_fc_squad_builder', <String, dynamic>{'p_squad_id': squadId});

  @override
  Future<Map<String, dynamic>> createSquad({
    required String fcAccountId,
    required String name,
    required String formationCode,
  }) => _map('create_fc_squad', <String, dynamic>{
    'p_fc_account_id': fcAccountId,
    'p_name': name,
    'p_formation_code': formationCode,
  });

  @override
  Future<Map<String, dynamic>> renameSquad({
    required String squadId,
    required String name,
  }) => _map('update_fc_squad', <String, dynamic>{
    'p_squad_id': squadId,
    'p_name': name,
  });

  @override
  Future<Map<String, dynamic>> setFormation({
    required String squadId,
    required String formationCode,
  }) => _map('set_fc_squad_formation', <String, dynamic>{
    'p_squad_id': squadId,
    'p_formation_code': formationCode,
  });

  @override
  Future<Map<String, dynamic>> setDefault(String squadId) =>
      _map('set_default_fc_squad', <String, dynamic>{'p_squad_id': squadId});

  @override
  Future<void> archiveSquad(String squadId) => _client.rpc<dynamic>(
    'archive_fc_squad',
    params: <String, dynamic>{'p_squad_id': squadId},
  );

  @override
  Future<Map<String, dynamic>> setSlot({
    required String squadId,
    required String slotType,
    required String slotCode,
    required String playerCardId,
  }) => _map('set_fc_squad_slot', <String, dynamic>{
    'p_squad_id': squadId,
    'p_slot_type': slotType,
    'p_slot_code': slotCode,
    'p_player_card_id': playerCardId,
  });

  @override
  Future<Map<String, dynamic>> clearSlot({
    required String squadId,
    required String slotType,
    required String slotCode,
  }) => _map('clear_fc_squad_slot', <String, dynamic>{
    'p_squad_id': squadId,
    'p_slot_type': slotType,
    'p_slot_code': slotCode,
  });

  @override
  Future<Map<String, dynamic>> swapSlots({
    required String squadId,
    required String fromType,
    required String fromCode,
    required String toType,
    required String toCode,
  }) => _map('swap_fc_squad_slots', <String, dynamic>{
    'p_squad_id': squadId,
    'p_from_type': fromType,
    'p_from_code': fromCode,
    'p_to_type': toType,
    'p_to_code': toCode,
  });

  @override
  Future<Map<String, dynamic>> setManager({
    required String squadId,
    String? managerId,
    String? managerLeagueId,
  }) => _map('set_fc_squad_manager', <String, dynamic>{
    'p_squad_id': squadId,
    'p_manager_id': managerId,
    'p_manager_league_id': managerLeagueId,
  });

  Future<Map<String, dynamic>> _map(
    String function,
    Map<String, dynamic> params,
  ) async {
    final response = await _client.rpc<dynamic>(function, params: params);
    return Map<String, dynamic>.from(response as Map);
  }
}
