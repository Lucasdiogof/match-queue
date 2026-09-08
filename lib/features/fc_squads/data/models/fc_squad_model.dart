import 'package:fifa_queue/features/fc_squads/domain/entities/fc_manager.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_player.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_squad.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/formation.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';

class FcSquadModel {
  const FcSquadModel._();

  static double _toDouble(Object? value) => switch (value) {
    final num n => n.toDouble(),
    final String s => double.tryParse(s) ?? 0,
    _ => 0,
  };

  static int _toInt(Object? value) => switch (value) {
    final int n => n,
    final num n => n.toInt(),
    final String s => int.tryParse(s) ?? 0,
    _ => 0,
  };

  static List<String> _toStringList(Object? value) => value is List
      ? value.map((e) => '$e').toList(growable: false)
      : const <String>[];

  static PlayerCard cardFromJson(Map<String, dynamic> json) => PlayerCard(
    id: '${json['id']}',
    provider: '${json['provider'] ?? 'LOCAL'}',
    playerName: '${json['player_name']}',
    commonName: json['common_name'] as String?,
    fcPlayerId: json['fc_player_id'] as String?,
    player: _playerFromJson(json['fc_player']),
    rating: _toInt(json['rating']),
    primaryPosition: '${json['primary_position']}',
    alternativePositions: _toStringList(json['alternative_positions']),
    pace: json['pace'] as int?,
    shooting: json['shooting'] as int?,
    passing: json['passing'] as int?,
    dribbling: json['dribbling'] as int?,
    defending: json['defending'] as int?,
    physical: json['physical'] as int?,
    playerImageUrl: json['player_image_url'] as String?,
    cardImageUrl: json['card_image_url'] as String?,
    clubName: json['club_name'] as String?,
    leagueName: json['league_name'] as String?,
    nationName: json['nation_name'] as String?,
    cardType: json['card_type'] as String?,
    gameVersion: '${json['game_version'] ?? 'FC27'}',
    gkDiving: json['gk_diving'] as int?,
    gkHandling: json['gk_handling'] as int?,
    gkKicking: json['gk_kicking'] as int?,
    gkReflexes: json['gk_reflexes'] as int?,
    gkSpeed: json['gk_speed'] as int?,
    gkPositioning: json['gk_positioning'] as int?,
    skillMoves: json['skill_moves'] as int?,
    weakFoot: json['weak_foot'] as int?,
    playstyles: _toStringList(json['playstyles']),
    heightCm: json['height_cm'] as int?,
    preferredFoot: json['preferred_foot'] as String?,
    playerRoles: _toStringList(json['player_roles']),
    rarity: json['rarity'] as String?,
  );

  static FcPlayer? _playerFromJson(Object? json) {
    if (json is! Map) {
      return null;
    }
    final m = Map<String, dynamic>.from(json);
    if (m['id'] == null || m['name'] == null) {
      return null;
    }
    return FcPlayer(
      id: '${m['id']}',
      name: '${m['name']}',
      commonName: m['common_name'] as String?,
      primaryPosition: m['primary_position'] as String?,
      imageUrl: m['image_url'] as String?,
      nationName: m['nation_name'] as String?,
      clubName: m['club_name'] as String?,
      leagueName: m['league_name'] as String?,
    );
  }

  static FcClub? clubFromJson(Object? json) {
    if (json is! Map) {
      return null;
    }
    final m = Map<String, dynamic>.from(json);
    if (m['id'] == null) {
      return null;
    }
    return FcClub(
      id: '${m['id']}',
      name: '${m['name']}',
      leagueId: m['league_id'] as String?,
      logoImageUrl: m['logo_image_url'] as String?,
    );
  }

  static FormationSlot _slotFromJson(Map<String, dynamic> json) =>
      FormationSlot(
        slotCode: '${json['slot_code']}',
        positionCode: '${json['position_code']}',
        x: _toDouble(json['x']),
        y: _toDouble(json['y']),
        sortOrder: _toInt(json['sort_order']),
      );

  static FormationDefinition formationFromJson(Map<String, dynamic> json) {
    final rawSlots = json['slots'];
    return FormationDefinition(
      code: '${json['code']}',
      displayName: '${json['display_name'] ?? json['code']}',
      slots: <FormationSlot>[
        if (rawSlots is List)
          for (final item in rawSlots)
            if (item is Map) _slotFromJson(Map<String, dynamic>.from(item)),
      ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
    );
  }

  static FcNation? nationFromJson(Object? json) {
    if (json is! Map) {
      return null;
    }
    final m = Map<String, dynamic>.from(json);
    if (m['id'] == null) {
      return null;
    }
    return FcNation(
      id: '${m['id']}',
      name: '${m['name']}',
      flagImageUrl: m['flag_image_url'] as String?,
    );
  }

  static FcLeague? leagueFromJson(Object? json) {
    if (json is! Map) {
      return null;
    }
    final m = Map<String, dynamic>.from(json);
    if (m['id'] == null) {
      return null;
    }
    return FcLeague(
      id: '${m['id']}',
      name: '${m['name']}',
      logoImageUrl: m['logo_image_url'] as String?,
    );
  }

  static FcManager? managerFromJson(Object? json) {
    if (json is! Map) {
      return null;
    }
    final m = Map<String, dynamic>.from(json);
    if (m['id'] == null) {
      return null;
    }
    return FcManager(
      id: '${m['id']}',
      name: '${m['name']}',
      nation: nationFromJson(m['nation']),
      imageUrl: m['image_url'] as String?,
    );
  }

  static FcSquadDetail detailFromJson(Map<String, dynamic> json) {
    final rawSlots = json['slots'];
    final formation = json['formation'];
    return FcSquadDetail(
      id: '${json['id']}',
      fcAccountId: '${json['fc_account_id']}',
      name: '${json['name']}',
      formation: formation is Map
          ? formationFromJson(Map<String, dynamic>.from(formation))
          : FormationDefinition(
              code: '${json['formation_code']}',
              displayName: '${json['formation_code']}',
              slots: const <FormationSlot>[],
            ),
      slots: <SquadSlot>[
        if (rawSlots is List)
          for (final item in rawSlots)
            if (item is Map && item['card'] is Map)
              SquadSlot(
                type: SquadSlotType.fromKey(item['slot_type']),
                slotCode: '${item['slot_code']}',
                card: cardFromJson(
                  Map<String, dynamic>.from(item['card'] as Map),
                ),
                chemistry: item['chemistry'] == null
                    ? null
                    : _toInt(item['chemistry']),
                positionEligible: item['position_eligible'] as bool? ?? true,
              ),
      ],
      isDefault: json['is_default'] as bool? ?? false,
      benchSize: _toInt(json['bench_size']),
      reserveSize: _toInt(json['reserve_size']),
      overall: json['overall'] == null ? null : _toInt(json['overall']),
      chemistry: _toInt(json['chemistry']),
      chemistryRuleVersion: json['chemistry_rule_version'] as String?,
      filledStarters: _toInt(json['filled_starters']),
      starterCount: json['starter_count'] == null
          ? 11
          : _toInt(json['starter_count']),
      manager: managerFromJson(json['manager']),
      managerLeague: leagueFromJson(json['manager_league']),
    );
  }

  static List<FcSquadSummary> summariesFromJson(
    Object? json,
  ) => <FcSquadSummary>[
    if (json is List)
      for (final item in json)
        if (item is Map)
          FcSquadSummary(
            id: '${item['id']}',
            fcAccountId: '${item['fc_account_id']}',
            name: '${item['name']}',
            formationCode: '${item['formation_code']}',
            isDefault: item['is_default'] as bool? ?? false,
            startingCount: _toInt(item['starting_count']),
            benchCount: _toInt(item['bench_count']),
            reserveCount: _toInt(item['reserve_count']),
            overall: item['overall'] == null ? null : _toInt(item['overall']),
            chemistry: _toInt(item['chemistry']),
          ),
  ];
}
