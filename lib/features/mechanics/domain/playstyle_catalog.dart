import 'package:fifa_queue/l10n/generated/app_localizations.dart';

/// Catálogo estático de PlayStyles do FC 27: nomes e categoria vêm de
/// pesquisa (FIFPlay), texto de efeito resumido com texto próprio -- nunca
/// copiado literalmente -- e resolvido via l10n (nunca hardcoded num só
/// idioma: [playstyleEffect]/[playstylePlusEffect] abaixo). A contagem de
/// cartas é sempre real, vinda de `get_fc_playstyle_summary` (nunca daqui).
///
/// Os nomes ('Finesse Shot' etc) são termos oficiais da EA e não mudam
/// entre idiomas -- só o texto explicativo é traduzido.
///
/// Os 35 nomes abaixo batem exatamente com os 35 valores distintos
/// encontrados em produção em `fc_player_cards.playstyles`/`playstyles_plus`
/// (auditado antes de implementar, Central/Mecânicas).
enum PlaystyleCategory {
  finishing,
  passing,
  defending,
  ballControl,
  physical,
  goalkeeper,
}

class PlaystyleInfo {
  const PlaystyleInfo({required this.name, required this.category});

  final String name;
  final PlaystyleCategory category;
}

const List<PlaystyleInfo> kPlaystyleCatalog = <PlaystyleInfo>[
  PlaystyleInfo(name: 'Finesse Shot', category: PlaystyleCategory.finishing),
  PlaystyleInfo(name: 'Chip Shot', category: PlaystyleCategory.finishing),
  PlaystyleInfo(name: 'Power Shot', category: PlaystyleCategory.finishing),
  PlaystyleInfo(name: 'Dead Ball', category: PlaystyleCategory.finishing),
  PlaystyleInfo(
    name: 'Precision Header',
    category: PlaystyleCategory.finishing,
  ),
  PlaystyleInfo(name: 'Acrobatic', category: PlaystyleCategory.finishing),
  PlaystyleInfo(name: 'Low Driven Shot', category: PlaystyleCategory.finishing),
  PlaystyleInfo(name: 'Gamechanger', category: PlaystyleCategory.finishing),
  PlaystyleInfo(name: 'Incisive Pass', category: PlaystyleCategory.passing),
  PlaystyleInfo(name: 'Pinged Pass', category: PlaystyleCategory.passing),
  PlaystyleInfo(name: 'Long Ball Pass', category: PlaystyleCategory.passing),
  PlaystyleInfo(name: 'Tiki Taka', category: PlaystyleCategory.passing),
  PlaystyleInfo(name: 'Whipped Pass', category: PlaystyleCategory.passing),
  PlaystyleInfo(name: 'Inventive', category: PlaystyleCategory.passing),
  PlaystyleInfo(name: 'Jockey', category: PlaystyleCategory.defending),
  PlaystyleInfo(name: 'Block', category: PlaystyleCategory.defending),
  PlaystyleInfo(name: 'Intercept', category: PlaystyleCategory.defending),
  PlaystyleInfo(name: 'Anticipate', category: PlaystyleCategory.defending),
  PlaystyleInfo(name: 'Slide Tackle', category: PlaystyleCategory.defending),
  PlaystyleInfo(name: 'Aerial Fortress', category: PlaystyleCategory.defending),
  PlaystyleInfo(name: 'Technical', category: PlaystyleCategory.ballControl),
  PlaystyleInfo(name: 'Rapid', category: PlaystyleCategory.ballControl),
  PlaystyleInfo(name: 'First Touch', category: PlaystyleCategory.ballControl),
  PlaystyleInfo(name: 'Trickster', category: PlaystyleCategory.ballControl),
  PlaystyleInfo(name: 'Press Proven', category: PlaystyleCategory.ballControl),
  PlaystyleInfo(name: 'Quick Step', category: PlaystyleCategory.physical),
  PlaystyleInfo(name: 'Relentless', category: PlaystyleCategory.physical),
  PlaystyleInfo(name: 'Long Throw', category: PlaystyleCategory.physical),
  PlaystyleInfo(name: 'Bruiser', category: PlaystyleCategory.physical),
  PlaystyleInfo(name: 'Enforcer', category: PlaystyleCategory.physical),
  PlaystyleInfo(name: 'Far Throw', category: PlaystyleCategory.goalkeeper),
  PlaystyleInfo(name: 'Footwork', category: PlaystyleCategory.goalkeeper),
  PlaystyleInfo(name: 'Cross Claimer', category: PlaystyleCategory.goalkeeper),
  PlaystyleInfo(name: 'Rush Out', category: PlaystyleCategory.goalkeeper),
  PlaystyleInfo(name: 'Far Reach', category: PlaystyleCategory.goalkeeper),
  PlaystyleInfo(name: 'Deflector', category: PlaystyleCategory.goalkeeper),
];

String playstyleCategoryLabel(
  AppLocalizations l10n,
  PlaystyleCategory category,
) => switch (category) {
  PlaystyleCategory.finishing => l10n.playstyleCategoryFinishing,
  PlaystyleCategory.passing => l10n.playstyleCategoryPassing,
  PlaystyleCategory.defending => l10n.playstyleCategoryDefending,
  PlaystyleCategory.ballControl => l10n.playstyleCategoryBallControl,
  PlaystyleCategory.physical => l10n.playstyleCategoryPhysical,
  PlaystyleCategory.goalkeeper => l10n.playstyleCategoryGoalkeeper,
};

PlaystyleInfo? findPlaystyleInfo(String name) =>
    kPlaystyleCatalog.where((info) => info.name == name).firstOrNull;

String playstyleEffect(AppLocalizations l10n, String name) => switch (name) {
  'Finesse Shot' => l10n.playstyleEffectFinesseShot,
  'Chip Shot' => l10n.playstyleEffectChipShot,
  'Power Shot' => l10n.playstyleEffectPowerShot,
  'Dead Ball' => l10n.playstyleEffectDeadBall,
  'Precision Header' => l10n.playstyleEffectPrecisionHeader,
  'Acrobatic' => l10n.playstyleEffectAcrobatic,
  'Low Driven Shot' => l10n.playstyleEffectLowDrivenShot,
  'Gamechanger' => l10n.playstyleEffectGamechanger,
  'Incisive Pass' => l10n.playstyleEffectIncisivePass,
  'Pinged Pass' => l10n.playstyleEffectPingedPass,
  'Long Ball Pass' => l10n.playstyleEffectLongBallPass,
  'Tiki Taka' => l10n.playstyleEffectTikiTaka,
  'Whipped Pass' => l10n.playstyleEffectWhippedPass,
  'Inventive' => l10n.playstyleEffectInventive,
  'Jockey' => l10n.playstyleEffectJockey,
  'Block' => l10n.playstyleEffectBlock,
  'Intercept' => l10n.playstyleEffectIntercept,
  'Anticipate' => l10n.playstyleEffectAnticipate,
  'Slide Tackle' => l10n.playstyleEffectSlideTackle,
  'Aerial Fortress' => l10n.playstyleEffectAerialFortress,
  'Technical' => l10n.playstyleEffectTechnical,
  'Rapid' => l10n.playstyleEffectRapid,
  'First Touch' => l10n.playstyleEffectFirstTouch,
  'Trickster' => l10n.playstyleEffectTrickster,
  'Press Proven' => l10n.playstyleEffectPressProven,
  'Quick Step' => l10n.playstyleEffectQuickStep,
  'Relentless' => l10n.playstyleEffectRelentless,
  'Long Throw' => l10n.playstyleEffectLongThrow,
  'Bruiser' => l10n.playstyleEffectBruiser,
  'Enforcer' => l10n.playstyleEffectEnforcer,
  'Far Throw' => l10n.playstyleEffectFarThrow,
  'Footwork' => l10n.playstyleEffectFootwork,
  'Cross Claimer' => l10n.playstyleEffectCrossClaimer,
  'Rush Out' => l10n.playstyleEffectRushOut,
  'Far Reach' => l10n.playstyleEffectFarReach,
  'Deflector' => l10n.playstyleEffectDeflector,
  _ => '',
};

String playstylePlusEffect(AppLocalizations l10n, String name) =>
    switch (name) {
      'Finesse Shot' => l10n.playstylePlusEffectFinesseShot,
      'Chip Shot' => l10n.playstylePlusEffectChipShot,
      'Power Shot' => l10n.playstylePlusEffectPowerShot,
      'Dead Ball' => l10n.playstylePlusEffectDeadBall,
      'Precision Header' => l10n.playstylePlusEffectPrecisionHeader,
      'Acrobatic' => l10n.playstylePlusEffectAcrobatic,
      'Low Driven Shot' => l10n.playstylePlusEffectLowDrivenShot,
      'Gamechanger' => l10n.playstylePlusEffectGamechanger,
      'Incisive Pass' => l10n.playstylePlusEffectIncisivePass,
      'Pinged Pass' => l10n.playstylePlusEffectPingedPass,
      'Long Ball Pass' => l10n.playstylePlusEffectLongBallPass,
      'Tiki Taka' => l10n.playstylePlusEffectTikiTaka,
      'Whipped Pass' => l10n.playstylePlusEffectWhippedPass,
      'Inventive' => l10n.playstylePlusEffectInventive,
      'Jockey' => l10n.playstylePlusEffectJockey,
      'Block' => l10n.playstylePlusEffectBlock,
      'Intercept' => l10n.playstylePlusEffectIntercept,
      'Anticipate' => l10n.playstylePlusEffectAnticipate,
      'Slide Tackle' => l10n.playstylePlusEffectSlideTackle,
      'Aerial Fortress' => l10n.playstylePlusEffectAerialFortress,
      'Technical' => l10n.playstylePlusEffectTechnical,
      'Rapid' => l10n.playstylePlusEffectRapid,
      'First Touch' => l10n.playstylePlusEffectFirstTouch,
      'Trickster' => l10n.playstylePlusEffectTrickster,
      'Press Proven' => l10n.playstylePlusEffectPressProven,
      'Quick Step' => l10n.playstylePlusEffectQuickStep,
      'Relentless' => l10n.playstylePlusEffectRelentless,
      'Long Throw' => l10n.playstylePlusEffectLongThrow,
      'Bruiser' => l10n.playstylePlusEffectBruiser,
      'Enforcer' => l10n.playstylePlusEffectEnforcer,
      'Far Throw' => l10n.playstylePlusEffectFarThrow,
      'Footwork' => l10n.playstylePlusEffectFootwork,
      'Cross Claimer' => l10n.playstylePlusEffectCrossClaimer,
      'Rush Out' => l10n.playstylePlusEffectRushOut,
      'Far Reach' => l10n.playstylePlusEffectFarReach,
      'Deflector' => l10n.playstylePlusEffectDeflector,
      _ => '',
    };
