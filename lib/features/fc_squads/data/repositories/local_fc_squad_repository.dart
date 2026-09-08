import 'dart:convert';
import 'dart:math';

import 'package:fifa_queue/features/fc_squads/domain/entities/fc_manager.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_squad.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/formation.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/fc_squads/domain/repositories/fc_squad_repository.dart';
import 'package:fifa_queue/features/fc_squads/domain/repositories/player_card_catalog_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modo local (sem Supabase). Guarda os squads em SharedPreferences e usa um
/// catálogo mínimo embutido -- honesto sobre o que é: três formações e um
/// punhado de cartas, o suficiente para abrir e mexer no builder sem
/// backend. Não tenta imitar o catálogo completo, que só existe no servidor.
class LocalFcSquadRepository implements FcSquadRepository {
  LocalFcSquadRepository(this._preferences, this._catalog);

  final SharedPreferences _preferences;
  final PlayerCardCatalogRepository _catalog;
  final Random _random = Random();

  static const String _key = 'fc_squads.local';

  @override
  Future<List<FormationDefinition>> listFormations() async =>
      LocalPlayerCardCatalogRepository.formations;

  @override
  Future<List<FcSquadSummary>> listSquads(String fcAccountId) async => _all()
      .where((s) => s.fcAccountId == fcAccountId)
      .map(
        (s) => FcSquadSummary(
          id: s.id,
          fcAccountId: s.fcAccountId,
          name: s.name,
          formationCode: s.formation.code,
          isDefault: s.isDefault,
          startingCount: s.startingCount,
          benchCount: s.benchCount,
        ),
      )
      .toList(growable: false);

  @override
  Future<FcSquadDetail> getBuilder(String squadId) async => _require(squadId);

  @override
  Future<FcSquadDetail> createSquad({
    required String fcAccountId,
    required String name,
    required String formationCode,
  }) async {
    final all = _all();
    final isFirst = all.every((s) => s.fcAccountId != fcAccountId);
    final squad = FcSquadDetail(
      id: _uuid(),
      fcAccountId: fcAccountId,
      name: name,
      formation: _formation(formationCode),
      slots: const <SquadSlot>[],
      isDefault: isFirst,
      benchSize: 7,
    );
    await _write(<FcSquadDetail>[...all, squad]);
    return squad;
  }

  @override
  Future<FcSquadDetail> renameSquad({
    required String squadId,
    required String name,
  }) => _update(squadId, (s) => _copy(s, name: name));

  @override
  Future<FcSquadDetail> setFormation({
    required String squadId,
    required String formationCode,
  }) => _update(squadId, (s) {
    final next = _formation(formationCode);
    final bench = s.slots.where((x) => x.type == SquadSlotType.bench);
    final starting = s.slots
        .where((x) => x.type == SquadSlotType.starting)
        .toList();
    // Mesmo espírito do backend: nunca perder carta. Reencaixa em ordem.
    final remapped = <SquadSlot>[
      for (var i = 0; i < starting.length && i < next.slots.length; i++)
        SquadSlot(
          type: SquadSlotType.starting,
          slotCode: next.slots[i].slotCode,
          card: starting[i].card,
        ),
    ];
    return _copy(s, formation: next, slots: <SquadSlot>[...remapped, ...bench]);
  });

  @override
  Future<FcSquadDetail> setDefault(String squadId) async {
    final target = _require(squadId);
    await _write(<FcSquadDetail>[
      for (final s in _all())
        if (s.fcAccountId != target.fcAccountId)
          s
        else
          _copy(s, isDefault: s.id == squadId),
    ]);
    return _require(squadId);
  }

  @override
  Future<void> archiveSquad(String squadId) async =>
      _write(_all().where((s) => s.id != squadId).toList(growable: false));

  @override
  Future<FcSquadDetail> setSlot({
    required String squadId,
    required SquadSlotType type,
    required String slotCode,
    required String playerCardId,
  }) async {
    final card = await _catalog.getCard(playerCardId);
    if (card == null) {
      return _require(squadId);
    }
    return _update(squadId, (s) {
      final kept = s.slots
          .where(
            (x) =>
                x.card.id != playerCardId &&
                !(x.type == type && x.slotCode == slotCode),
          )
          .toList();
      return _copy(
        s,
        slots: <SquadSlot>[
          ...kept,
          SquadSlot(type: type, slotCode: slotCode, card: card),
        ],
      );
    });
  }

  @override
  Future<FcSquadDetail> clearSlot({
    required String squadId,
    required SquadSlotType type,
    required String slotCode,
  }) => _update(
    squadId,
    (s) => _copy(
      s,
      slots: s.slots
          .where((x) => !(x.type == type && x.slotCode == slotCode))
          .toList(growable: false),
    ),
  );

  @override
  Future<FcSquadDetail> swapSlots({
    required String squadId,
    required SquadSlotType fromType,
    required String fromCode,
    required SquadSlotType toType,
    required String toCode,
  }) => _update(squadId, (s) {
    final from = s.cardAt(fromType, fromCode);
    final to = s.cardAt(toType, toCode);
    final rest = s.slots
        .where(
          (x) =>
              !(x.type == fromType && x.slotCode == fromCode) &&
              !(x.type == toType && x.slotCode == toCode),
        )
        .toList();
    return _copy(
      s,
      slots: <SquadSlot>[
        ...rest,
        if (from != null) SquadSlot(type: toType, slotCode: toCode, card: from),
        if (to != null) SquadSlot(type: fromType, slotCode: fromCode, card: to),
      ],
    );
  });

  @override
  Future<FcSquadDetail> setManager({
    required String squadId,
    String? managerId,
    String? managerLeagueId,
  }) async {
    final managers = await _catalog.searchManagers();
    final leagues = await _catalog.getLeagues();
    return _update(squadId, (s) {
      final manager = managerId == null
          ? null
          : managers.where((m) => m.id == managerId).firstOrNull;
      return _copy(
        s,
        manager: manager,
        managerLeague: manager == null || managerLeagueId == null
            ? null
            : leagues.where((l) => l.id == managerLeagueId).firstOrNull,
        clearManager: manager == null,
      );
    });
  }

  FormationDefinition _formation(String code) =>
      LocalPlayerCardCatalogRepository.formations.firstWhere(
        (f) => f.code == code,
        orElse: () => LocalPlayerCardCatalogRepository.formations.first,
      );

  FcSquadDetail _require(String squadId) =>
      _all().firstWhere((s) => s.id == squadId);

  Future<FcSquadDetail> _update(
    String squadId,
    FcSquadDetail Function(FcSquadDetail) change,
  ) async {
    final updated = <FcSquadDetail>[
      for (final s in _all())
        if (s.id == squadId) change(s) else s,
    ];
    await _write(updated);
    return _require(squadId);
  }

  FcSquadDetail _copy(
    FcSquadDetail s, {
    String? name,
    FormationDefinition? formation,
    List<SquadSlot>? slots,
    bool? isDefault,
    FcManager? manager,
    FcLeague? managerLeague,
    bool clearManager = false,
  }) => FcSquadDetail(
    id: s.id,
    fcAccountId: s.fcAccountId,
    name: name ?? s.name,
    formation: formation ?? s.formation,
    slots: slots ?? s.slots,
    isDefault: isDefault ?? s.isDefault,
    benchSize: s.benchSize,
    manager: clearManager ? null : (manager ?? s.manager),
    managerLeague: clearManager ? null : (managerLeague ?? s.managerLeague),
  );

  List<FcSquadDetail> _all() {
    final raw = _preferences.getString(_key);
    if (raw == null || raw.isEmpty) {
      return const <FcSquadDetail>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <FcSquadDetail>[];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_fromJson)
          .toList(growable: false);
    } on FormatException {
      return const <FcSquadDetail>[];
    }
  }

  Future<void> _write(List<FcSquadDetail> squads) => _preferences.setString(
    _key,
    jsonEncode(squads.map(_toJson).toList(growable: false)),
  );

  Map<String, dynamic> _toJson(FcSquadDetail s) => <String, dynamic>{
    'id': s.id,
    'fc_account_id': s.fcAccountId,
    'name': s.name,
    'formation_code': s.formation.code,
    'is_default': s.isDefault,
    'manager_id': s.manager?.id,
    'manager_league_id': s.managerLeague?.id,
    'slots': <Map<String, dynamic>>[
      for (final slot in s.slots)
        <String, dynamic>{
          'slot_type': slot.type.key,
          'slot_code': slot.slotCode,
          'card_id': slot.card.id,
        },
    ],
  };

  FcSquadDetail _fromJson(Map<String, dynamic> json) {
    final cards = LocalPlayerCardCatalogRepository.cards;
    final rawSlots = json['slots'];
    return FcSquadDetail(
      id: '${json['id']}',
      fcAccountId: '${json['fc_account_id']}',
      name: '${json['name']}',
      formation: _formation('${json['formation_code']}'),
      slots: <SquadSlot>[
        if (rawSlots is List)
          for (final item in rawSlots)
            if (item is Map) ?_slot(Map<String, dynamic>.from(item), cards),
      ],
      isDefault: json['is_default'] as bool? ?? false,
      benchSize: 7,
    );
  }

  SquadSlot? _slot(Map<String, dynamic> json, List<PlayerCard> cards) {
    final card = cards.where((c) => c.id == '${json['card_id']}').firstOrNull;
    if (card == null) {
      return null;
    }
    return SquadSlot(
      type: SquadSlotType.fromKey(json['slot_type']),
      slotCode: '${json['slot_code']}',
      card: card,
    );
  }

  String _uuid() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

/// Catálogo mínimo do modo local. Não finge ser FUT.GG nem EA: são cartas de
/// desenvolvimento, com nomes inventados, só para o builder ter o que
/// mostrar sem backend.
class LocalPlayerCardCatalogRepository implements PlayerCardCatalogRepository {
  const LocalPlayerCardCatalogRepository();

  static const List<String> _positions = <String>[
    'GK',
    'CB',
    'CB',
    'LB',
    'RB',
    'CDM',
    'CM',
    'CM',
    'CAM',
    'LM',
    'RM',
    'LW',
    'RW',
    'ST',
    'ST',
    'CF',
    'LWB',
    'RWB',
  ];

  static final List<PlayerCard> cards = <PlayerCard>[
    for (var i = 0; i < _positions.length * 2; i++)
      PlayerCard(
        id: 'local-card-$i',
        provider: 'LOCAL',
        playerName: 'Jogador ${String.fromCharCode(65 + (i % 26))}$i',
        rating: 74 + (i * 7) % 18,
        primaryPosition: _positions[i % _positions.length],
        alternativePositions: const <String>[],
        pace: 60 + (i * 3) % 35,
        shooting: 60 + (i * 5) % 35,
        passing: 60 + (i * 7) % 35,
        dribbling: 60 + (i * 11) % 35,
        defending: 55 + (i * 13) % 40,
        physical: 60 + (i * 17) % 35,
      ),
  ];

  static final List<FormationDefinition> formations = <FormationDefinition>[
    _build('4-4-2', <List<Object>>[
      ['GK', 'GK', 0.50, 0.06],
      ['LB', 'LB', 0.14, 0.24],
      ['CB1', 'CB', 0.38, 0.24],
      ['CB2', 'CB', 0.62, 0.24],
      ['RB', 'RB', 0.86, 0.24],
      ['LM', 'LM', 0.14, 0.53],
      ['CM1', 'CM', 0.38, 0.53],
      ['CM2', 'CM', 0.62, 0.53],
      ['RM', 'RM', 0.86, 0.53],
      ['ST1', 'ST', 0.34, 0.90],
      ['ST2', 'ST', 0.66, 0.90],
    ]),
    _build('4-3-3', <List<Object>>[
      ['GK', 'GK', 0.50, 0.06],
      ['LB', 'LB', 0.14, 0.24],
      ['CB1', 'CB', 0.38, 0.24],
      ['CB2', 'CB', 0.62, 0.24],
      ['RB', 'RB', 0.86, 0.24],
      ['CM1', 'CM', 0.22, 0.53],
      ['CM2', 'CM', 0.50, 0.53],
      ['CM3', 'CM', 0.78, 0.53],
      ['LW', 'LW', 0.22, 0.90],
      ['ST', 'ST', 0.50, 0.90],
      ['RW', 'RW', 0.78, 0.90],
    ]),
    _build('4-2-3-1', <List<Object>>[
      ['GK', 'GK', 0.50, 0.06],
      ['LB', 'LB', 0.14, 0.24],
      ['CB1', 'CB', 0.38, 0.24],
      ['CB2', 'CB', 0.62, 0.24],
      ['RB', 'RB', 0.86, 0.24],
      ['CDM1', 'CDM', 0.34, 0.40],
      ['CDM2', 'CDM', 0.66, 0.40],
      ['CAM1', 'CAM', 0.22, 0.68],
      ['CAM2', 'CAM', 0.50, 0.68],
      ['CAM3', 'CAM', 0.78, 0.68],
      ['ST', 'ST', 0.50, 0.90],
    ]),
  ];

  static FormationDefinition _build(String code, List<List<Object>> slots) =>
      FormationDefinition(
        code: code,
        displayName: code,
        slots: <FormationSlot>[
          for (var i = 0; i < slots.length; i++)
            FormationSlot(
              slotCode: slots[i][0] as String,
              positionCode: slots[i][1] as String,
              x: slots[i][2] as double,
              y: slots[i][3] as double,
              sortOrder: i + 1,
            ),
        ],
      );

  @override
  Future<PlayerCardPage> searchCards(PlayerCardQuery query) async {
    final position = query.position;
    final text = query.query?.toLowerCase();
    final filtered =
        cards
            .where((c) => position == null || c.canPlayIn(position))
            .where(
              (c) => text == null || c.displayName.toLowerCase().contains(text),
            )
            .toList()
          ..sort((a, b) => b.rating.compareTo(a.rating));
    final start = query.offset.clamp(0, filtered.length);
    final end = (start + query.limit).clamp(0, filtered.length);
    return PlayerCardPage(
      items: filtered.sublist(start, end),
      hasMore: end < filtered.length,
    );
  }

  @override
  Future<PlayerCard?> getCard(String id) async =>
      cards.where((c) => c.id == id).firstOrNull;

  @override
  Future<List<FcManager>> searchManagers({
    String? nationId,
    String? query,
  }) async {
    final nations = await getNations();
    return <FcManager>[
      for (var i = 0; i < 8; i++)
        FcManager(
          id: 'local-manager-$i',
          name: 'Técnico ${String.fromCharCode(65 + i)}',
          nation: nations[i % nations.length],
        ),
    ].where((m) => nationId == null || m.nation?.id == nationId).toList();
  }

  @override
  Future<List<FcNation>> getNations() async => const <FcNation>[
    FcNation(id: 'local-nation-1', name: 'Brasil'),
    FcNation(id: 'local-nation-2', name: 'Argentina'),
    FcNation(id: 'local-nation-3', name: 'Portugal'),
    FcNation(id: 'local-nation-4', name: 'Espanha'),
  ];

  @override
  Future<List<FcLeague>> getLeagues() async => const <FcLeague>[
    FcLeague(id: 'local-league-1', name: 'Liga Nacional'),
    FcLeague(id: 'local-league-2', name: 'Liga Continental'),
  ];
}
