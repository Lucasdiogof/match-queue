import 'dart:convert';

import 'package:fifa_queue/core/storage/cached_value.dart';
import 'package:fifa_queue/features/account/domain/entities/account.dart';
import 'package:fifa_queue/features/account/domain/entities/platform.dart';
import 'package:fifa_queue/features/account/domain/entities/rivals_division.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ultima conta carregada com sucesso, para a aba Jogar abrir sem rede.
///
/// Guarda so o que e estavel (nome, plataformas, divisao, times): placar,
/// campanha vigente e qualquer coisa de fila/pareamento dependem do servidor
/// e ficam de fora. Uma unica conta por aparelho -- gravar outra descarta a
/// anterior, e [clear] roda ao sair.
class AccountCacheStore {
  const AccountCacheStore(this._preferences);

  final SharedPreferences _preferences;

  static const String _key = 'account.cache.v1';

  CachedValue<Account>? read(String userId) {
    try {
      final raw = _preferences.getString(_key);
      if (raw == null) {
        return null;
      }
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['user_id'] != userId) {
        return null;
      }
      final data = json['data'] as Map<String, dynamic>;
      final savedAt = DateTime.tryParse('${json['saved_at']}');
      if (savedAt == null) {
        return null;
      }
      return CachedValue<Account>(_fromJson(data), savedAt);
    } on Object {
      // Cache corrompido ou de outra versao: tratado como ausente.
      return null;
    }
  }

  Future<void> write(Account account, {DateTime? now}) async {
    final payload = <String, dynamic>{
      'user_id': account.id,
      'saved_at': (now ?? DateTime.now()).toUtc().toIso8601String(),
      'data': _toJson(account),
    };
    await _preferences.setString(_key, jsonEncode(payload));
  }

  Future<void> clear() => _preferences.remove(_key);

  static Map<String, dynamic> _toJson(Account account) => <String, dynamic>{
    'id': account.id,
    'display_name': account.displayName,
    'avatar_url': account.avatarUrl,
    'locale': account.locale,
    'platforms': <String>[for (final p in account.platforms) p.key],
    'rivals_division': account.rivalsDivision?.key,
    'team_ids': account.teamIds,
    'created_at': account.createdAt.toUtc().toIso8601String(),
    'updated_at': account.updatedAt.toUtc().toIso8601String(),
  };

  static Account _fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse('${json['created_at']}');
    return Account(
      id: '${json['id']}',
      displayName: '${json['display_name']}',
      avatarUrl: json['avatar_url'] as String?,
      locale: json['locale'] as String?,
      platforms: <Platform>[
        for (final key in json['platforms'] as List<dynamic>)
          ?Platform.tryFromKey(key),
      ],
      rivalsDivision: RivalsDivision.tryFromKey(json['rivals_division']),
      teamIds: <String>[
        for (final id in json['team_ids'] as List<dynamic>) '$id',
      ],
      createdAt: createdAt,
      updatedAt: DateTime.tryParse('${json['updated_at']}') ?? createdAt,
    );
  }
}
