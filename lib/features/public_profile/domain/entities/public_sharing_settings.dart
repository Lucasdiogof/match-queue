import 'package:equatable/equatable.dart';

/// Configuração de exposição do perfil público do próprio usuário -- nunca
/// os dados de outra pessoa. Espelha `user_public_profiles`, que tem
/// `user_id` como chave: uma linha por usuário autenticado.
class PublicSharingSettings extends Equatable {
  const PublicSharingSettings({
    required this.isEnabled,
    this.slug,
    this.showSquad = true,
    this.showWeekendLeague = true,
    this.showRivals = true,
    this.showStats = true,
  });

  static const PublicSharingSettings empty = PublicSharingSettings(
    isEnabled: false,
  );

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
    isEnabled: isEnabled ?? this.isEnabled,
    slug: clearSlug ? null : (slug ?? this.slug),
    showSquad: showSquad ?? this.showSquad,
    showWeekendLeague: showWeekendLeague ?? this.showWeekendLeague,
    showRivals: showRivals ?? this.showRivals,
    showStats: showStats ?? this.showStats,
  );

  @override
  List<Object?> get props => <Object?>[
    isEnabled,
    slug,
    showSquad,
    showWeekendLeague,
    showRivals,
    showStats,
  ];
}
