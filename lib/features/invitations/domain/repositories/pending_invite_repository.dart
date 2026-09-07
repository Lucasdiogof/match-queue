import 'package:fifa_queue/features/invitations/domain/entities/pending_invite.dart';

abstract interface class PendingInviteRepository {
  PendingInvite? read();

  Future<void> save(String code);

  Future<void> clear();
}
