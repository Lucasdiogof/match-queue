import 'dart:convert';

import 'package:fifa_queue/features/invitations/domain/entities/pending_invite.dart';
import 'package:fifa_queue/features/invitations/domain/repositories/pending_invite_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalPendingInviteRepository implements PendingInviteRepository {
  const LocalPendingInviteRepository(this._preferences);

  static const String _key = 'invitations.pending';

  final SharedPreferences _preferences;

  @override
  PendingInvite? read() {
    final raw = _preferences.getString(_key);
    if (raw == null) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final code = decoded['code'];
    final capturedAt = DateTime.tryParse('${decoded['captured_at']}');
    if (code is! String || capturedAt == null) {
      return null;
    }

    final invite = PendingInvite(code: code, capturedAt: capturedAt);
    return invite.isExpired(DateTime.now().toUtc()) ? null : invite;
  }

  @override
  Future<void> save(String code) => _preferences.setString(
    _key,
    jsonEncode(<String, dynamic>{
      'code': InviteCode.normalize(code),
      'captured_at': DateTime.now().toUtc().toIso8601String(),
    }),
  );

  @override
  Future<void> clear() => _preferences.remove(_key);
}
