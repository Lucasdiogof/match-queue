import 'dart:convert';

import 'package:fifa_queue/core/storage/cached_value.dart';
import 'package:fifa_queue/features/teams/domain/entities/team.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_membership.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_role.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ultima lista de "Meus times" carregada com sucesso, para a aba Jogar
/// mostrar o time selecionado sem rede. Uma conta por aparelho: gravar para
/// outro usuario descarta a lista anterior, e [clear] roda ao sair.
class TeamsCacheStore {
  const TeamsCacheStore(this._preferences);

  final SharedPreferences _preferences;

  static const String _key = 'teams.cache.v1';

  CachedValue<List<UserTeam>>? read(String userId) {
    try {
      final raw = _preferences.getString(_key);
      if (raw == null) {
        return null;
      }
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['user_id'] != userId) {
        return null;
      }
      final savedAt = DateTime.tryParse('${json['saved_at']}');
      if (savedAt == null) {
        return null;
      }
      return CachedValue<List<UserTeam>>(<UserTeam>[
        for (final entry in json['teams'] as List<dynamic>)
          _fromJson(entry as Map<String, dynamic>),
      ], savedAt);
    } on Object {
      return null;
    }
  }

  Future<void> write(
    String userId,
    List<UserTeam> teams, {
    DateTime? now,
  }) async {
    final payload = <String, dynamic>{
      'user_id': userId,
      'saved_at': (now ?? DateTime.now()).toUtc().toIso8601String(),
      'teams': <Map<String, dynamic>>[for (final team in teams) _toJson(team)],
    };
    await _preferences.setString(_key, jsonEncode(payload));
  }

  Future<void> clear() => _preferences.remove(_key);

  static Map<String, dynamic> _toJson(UserTeam userTeam) {
    final team = userTeam.team;
    return <String, dynamic>{
      'id': team.id,
      'name': team.name,
      'tag': team.tag,
      'logo_url': team.logoUrl,
      'primary_color': team.primaryColor,
      'secondary_color': team.secondaryColor,
      'search_duration_seconds': team.defaultSearchDuration.inSeconds,
      'is_active': team.isActive,
      'is_public': team.isPublic,
      'created_at': team.createdAt.toUtc().toIso8601String(),
      'updated_at': team.updatedAt.toUtc().toIso8601String(),
      'role': userTeam.role.key,
      'joined_at': userTeam.joinedAt.toUtc().toIso8601String(),
    };
  }

  static UserTeam _fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse('${json['created_at']}');
    return UserTeam(
      team: Team(
        id: '${json['id']}',
        name: '${json['name']}',
        tag: json['tag'] as String?,
        logoUrl: json['logo_url'] as String?,
        primaryColor: json['primary_color'] as String?,
        secondaryColor: json['secondary_color'] as String?,
        defaultSearchDuration: Duration(
          seconds: json['search_duration_seconds'] as int,
        ),
        isActive: json['is_active'] as bool,
        isPublic: json['is_public'] as bool,
        createdAt: createdAt,
        updatedAt: DateTime.tryParse('${json['updated_at']}') ?? createdAt,
      ),
      role: TeamRole.fromKey(json['role']),
      joinedAt: DateTime.parse('${json['joined_at']}'),
    );
  }
}
