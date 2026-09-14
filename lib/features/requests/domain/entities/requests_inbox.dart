import 'package:equatable/equatable.dart';

/// Convite direto (time -> usuario) pendente para o usuario logado.
class TeamInvitationSummary extends Equatable {
  const TeamInvitationSummary({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.memberCount,
    required this.createdAt,
    this.teamTag,
    this.teamLogoUrl,
    this.fcAccountName,
  });

  final String id;
  final String teamId;
  final String teamName;
  final String? teamTag;
  final String? teamLogoUrl;
  final int memberCount;
  final String? fcAccountName;
  final DateTime createdAt;

  @override
  List<Object?> get props => <Object?>[
    id,
    teamId,
    teamName,
    teamTag,
    teamLogoUrl,
    memberCount,
    fcAccountName,
    createdAt,
  ];
}

/// Pedido de entrada (usuario -> time) pendente num time que o usuario
/// logado administra (OWNER ou ADMIN/gerente).
class TeamJoinRequestSummary extends Equatable {
  const TeamJoinRequestSummary({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.requesterUserId,
    required this.requesterDisplayName,
    required this.createdAt,
    this.requesterAvatarUrl,
    this.fcAccountName,
  });

  final String id;
  final String teamId;
  final String teamName;
  final String requesterUserId;
  final String requesterDisplayName;
  final String? requesterAvatarUrl;
  final String? fcAccountName;
  final DateTime createdAt;

  @override
  List<Object?> get props => <Object?>[
    id,
    teamId,
    teamName,
    requesterUserId,
    requesterDisplayName,
    requesterAvatarUrl,
    fcAccountName,
    createdAt,
  ];
}

/// Convite direto (time -> usuario) PENDING que o proprio time enviou --
/// usado pela tela do time pra listar/cancelar, nunca pela tab
/// Solicitacoes (que so mostra o que o usuario logado recebeu).
class SentTeamInvitation extends Equatable {
  const SentTeamInvitation({
    required this.id,
    required this.inviteeUserId,
    required this.inviteeDisplayName,
    required this.createdAt,
    this.inviteeAvatarUrl,
  });

  final String id;
  final String inviteeUserId;
  final String inviteeDisplayName;
  final String? inviteeAvatarUrl;
  final DateTime createdAt;

  @override
  List<Object?> get props => <Object?>[
    id,
    inviteeUserId,
    inviteeDisplayName,
    inviteeAvatarUrl,
    createdAt,
  ];
}

class RequestsInbox extends Equatable {
  const RequestsInbox({
    required this.invitationsReceived,
    required this.joinRequestsToReview,
  });

  const RequestsInbox.empty()
    : invitationsReceived = const <TeamInvitationSummary>[],
      joinRequestsToReview = const <TeamJoinRequestSummary>[];

  final List<TeamInvitationSummary> invitationsReceived;
  final List<TeamJoinRequestSummary> joinRequestsToReview;

  int get pendingCount =>
      invitationsReceived.length + joinRequestsToReview.length;

  @override
  List<Object?> get props => <Object?>[
    invitationsReceived,
    joinRequestsToReview,
  ];
}
