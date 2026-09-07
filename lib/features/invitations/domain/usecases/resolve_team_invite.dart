import 'package:fifa_queue/features/invitations/domain/entities/invite_preview.dart';
import 'package:fifa_queue/features/invitations/domain/entities/pending_invite.dart';
import 'package:fifa_queue/features/invitations/domain/repositories/invite_repository.dart';

/// Resolve um convite pelo codigo. Valida o formato no cliente antes de
/// bater na rede -- um codigo obviamente mal formado (link truncado, texto
/// colado errado) vira "invalido" na hora, sem round-trip.
class ResolveTeamInvite {
  const ResolveTeamInvite(this._repository);

  final InviteRepository _repository;

  Future<InvitePreview> call(String code) {
    final normalized = InviteCode.normalize(code);
    if (!InviteCode.isValid(normalized)) {
      return Future.value(const InvitePreview(status: InviteStatus.invalid));
    }
    return _repository.resolveInvite(normalized);
  }
}
