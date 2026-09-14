import 'package:equatable/equatable.dart';

/// Configuração de exposição do perfil público de UMA CONTA FC -- nunca os
/// dados de outra pessoa nem de outra conta. Espelha `user_public_profiles`,
/// que agora tem `fc_account_id` como chave: cada conta tem seu próprio
/// link/slug/toggles, totalmente independentes de qualquer outra conta do
/// mesmo dono.
class PublicSharingSettings extends Equatable {
  const PublicSharingSettings({
    required this.fcAccountId,
    required this.isEnabled,
    this.slug,
    this.showSquad = true,
    this.showWeekendLeague = true,
    this.showRivals = true,
    this.showStats = true,
  });

  static PublicSharingSettings empty(String fcAccountId) =>
      PublicSharingSettings(fcAccountId: fcAccountId, isEnabled: false);

  /// Identidade fixa da linha -- nunca muda via [copyWith]. Trocar de conta
  /// é editar OUTRA [PublicSharingSettings], não mutar esta.
  final String fcAccountId;
  final bool isEnabled;
  final String? slug;
  final bool showSquad;
  final bool showWeekendLeague;
  final bool showRivals;
  final bool showStats;

  PublicSharingSettings copyWith({
    bool? isEnabled,
    String? slug,
    bool clearSlug = false,
    bool? showSquad,
    bool? showWeekendLeague,
    bool? showRivals,
    bool? showStats,
  }) => PublicSharingSettings(
    fcAccountId: fcAccountId,
    isEnabled: isEnabled ?? this.isEnabled,
    slug: clearSlug ? null : (slug ?? this.slug),
    showSquad: showSquad ?? this.showSquad,
    showWeekendLeague: showWeekendLeague ?? this.showWeekendLeague,
    showRivals: showRivals ?? this.showRivals,
    showStats: showStats ?? this.showStats,
  );

  @override
  List<Object?> get props => <Object?>[
    fcAccountId,
    isEnabled,
    slug,
    showSquad,
    showWeekendLeague,
    showRivals,
    showStats,
  ];
}
