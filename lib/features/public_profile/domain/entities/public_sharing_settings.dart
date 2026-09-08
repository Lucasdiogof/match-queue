import 'package:equatable/equatable.dart';

/// Configuração de exposição do perfil público do próprio usuário -- nunca
/// os dados de outra pessoa. Espelha `user_public_profiles`.
class PublicSharingSettings extends Equatable {
  const PublicSharingSettings({
    required this.isEnabled,
    this.slug,
    this.fcAccountId,
    this.showSquad = false,
    this.showWeekendLeague = false,
    this.showRivals = false,
    this.showStats = false,
  });

  static const PublicSharingSettings empty = PublicSharingSettings(
    isEnabled: false,
  );

  final bool isEnabled;
  final String? slug;
  final String? fcAccountId;
  final bool showSquad;
  final bool showWeekendLeague;
  final bool showRivals;
  final bool showStats;

  PublicSharingSettings copyWith({
    bool? isEnabled,
    String? slug,
    bool clearSlug = false,
    String? fcAccountId,
    bool clearFcAccountId = false,
    bool? showSquad,
    bool? showWeekendLeague,
    bool? showRivals,
    bool? showStats,
  }) => PublicSharingSettings(
    isEnabled: isEnabled ?? this.isEnabled,
    slug: clearSlug ? null : (slug ?? this.slug),
    fcAccountId: clearFcAccountId ? null : (fcAccountId ?? this.fcAccountId),
    showSquad: showSquad ?? this.showSquad,
    showWeekendLeague: showWeekendLeague ?? this.showWeekendLeague,
    showRivals: showRivals ?? this.showRivals,
    showStats: showStats ?? this.showStats,
  );

  @override
  List<Object?> get props => <Object?>[
    isEnabled,
    slug,
    fcAccountId,
    showSquad,
    showWeekendLeague,
    showRivals,
    showStats,
  ];
}
