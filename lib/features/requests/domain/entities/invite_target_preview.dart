import 'package:equatable/equatable.dart';

/// Preview minimo de quem sera convidado, resolvido pelo slug do perfil
/// publico. Nunca carrega stats/squad -- so identidade, pra confirmar "e essa
/// pessoa mesmo" antes de enviar.
class InviteTargetPreview extends Equatable {
  const InviteTargetPreview({
    required this.found,
    this.userId,
    this.displayName,
    this.avatarUrl,
    this.fcAccountName,
  });

  const InviteTargetPreview.notFound() : this(found: false);

  final bool found;
  final String? userId;
  final String? displayName;
  final String? avatarUrl;
  final String? fcAccountName;

  @override
  List<Object?> get props => <Object?>[
    found,
    userId,
    displayName,
    avatarUrl,
    fcAccountName,
  ];
}
