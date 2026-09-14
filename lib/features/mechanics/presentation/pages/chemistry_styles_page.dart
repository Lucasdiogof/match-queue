import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/mechanics/presentation/widgets/guide_widgets.dart';
import 'package:fifa_queue/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class _ChemistryStyleInfo {
  const _ChemistryStyleInfo(this.name, this.boosts, this.bestFor);

  final String name;
  final String boosts;
  final String bestFor;
}

/// Chemistry Styles: item base de Ultimate Team (tecnicamente um
/// consumível), mas mantido em Mecânicas por decisão explícita do dono do
/// produto -- não duplicar em Consumíveis.
///
/// Nenhuma carta do nosso catálogo grava qual Chemistry Style está
/// aplicado (isso é escolha de squad do jogador, não dado da carta), então
/// esta tela é só o catálogo de estilos -- sem associação com cartas. Nomes
/// ('Basic', 'Sniper' etc) são termos oficiais da EA e não mudam entre
/// idiomas -- só boosts/bestFor (via l10n) são traduzidos.
List<_ChemistryStyleInfo> _styles(AppLocalizations l10n) =>
    <_ChemistryStyleInfo>[
      _ChemistryStyleInfo(
        'Basic',
        l10n.chemistryStyleBoostsBasic,
        l10n.chemistryStyleBestForBasic,
      ),
      _ChemistryStyleInfo(
        'Sniper',
        l10n.chemistryStyleBoostsSniper,
        l10n.chemistryStyleBestForSniper,
      ),
      _ChemistryStyleInfo(
        'Finisher',
        l10n.chemistryStyleBoostsFinisher,
        l10n.chemistryStyleBestForFinisher,
      ),
      _ChemistryStyleInfo(
        'Deadeye',
        l10n.chemistryStyleBoostsDeadeye,
        l10n.chemistryStyleBestForDeadeye,
      ),
      _ChemistryStyleInfo(
        'Marksman',
        l10n.chemistryStyleBoostsMarksman,
        l10n.chemistryStyleBestForMarksman,
      ),
      _ChemistryStyleInfo(
        'Hawk',
        l10n.chemistryStyleBoostsHawk,
        l10n.chemistryStyleBestForHawk,
      ),
      _ChemistryStyleInfo(
        'Artist',
        l10n.chemistryStyleBoostsArtist,
        l10n.chemistryStyleBestForArtist,
      ),
      _ChemistryStyleInfo(
        'Architect',
        l10n.chemistryStyleBoostsArchitect,
        l10n.chemistryStyleBestForArchitect,
      ),
      _ChemistryStyleInfo(
        'Powerhouse',
        l10n.chemistryStyleBoostsPowerhouse,
        l10n.chemistryStyleBestForPowerhouse,
      ),
      _ChemistryStyleInfo(
        'Maestro',
        l10n.chemistryStyleBoostsMaestro,
        l10n.chemistryStyleBestForMaestro,
      ),
      _ChemistryStyleInfo(
        'Engine',
        l10n.chemistryStyleBoostsEngine,
        l10n.chemistryStyleBestForEngine,
      ),
      _ChemistryStyleInfo(
        'Sentinel',
        l10n.chemistryStyleBoostsSentinel,
        l10n.chemistryStyleBestForSentinel,
      ),
      _ChemistryStyleInfo(
        'Guardian',
        l10n.chemistryStyleBoostsGuardian,
        l10n.chemistryStyleBestForGuardian,
      ),
      _ChemistryStyleInfo(
        'Gladiator',
        l10n.chemistryStyleBoostsGladiator,
        l10n.chemistryStyleBestForGladiator,
      ),
      _ChemistryStyleInfo(
        'Backbone',
        l10n.chemistryStyleBoostsBackbone,
        l10n.chemistryStyleBestForBackbone,
      ),
      _ChemistryStyleInfo(
        'Anchor',
        l10n.chemistryStyleBoostsAnchor,
        l10n.chemistryStyleBestForAnchor,
      ),
      _ChemistryStyleInfo(
        'Hunter',
        l10n.chemistryStyleBoostsHunter,
        l10n.chemistryStyleBestForHunter,
      ),
      _ChemistryStyleInfo(
        'Catalyst',
        l10n.chemistryStyleBoostsCatalyst,
        l10n.chemistryStyleBestForCatalyst,
      ),
      _ChemistryStyleInfo(
        'Shadow',
        l10n.chemistryStyleBoostsShadow,
        l10n.chemistryStyleBestForShadow,
      ),
      _ChemistryStyleInfo(
        'Wall',
        l10n.chemistryStyleBoostsWall,
        l10n.chemistryStyleBestForWall,
      ),
      _ChemistryStyleInfo(
        'Shield',
        l10n.chemistryStyleBoostsShield,
        l10n.chemistryStyleBestForShield,
      ),
      _ChemistryStyleInfo(
        'Cat',
        l10n.chemistryStyleBoostsCat,
        l10n.chemistryStyleBestForCat,
      ),
      _ChemistryStyleInfo(
        'Glove',
        l10n.chemistryStyleBoostsGlove,
        l10n.chemistryStyleBestForGlove,
      ),
      _ChemistryStyleInfo(
        'Basic (GK)',
        l10n.chemistryStyleBoostsBasicGk,
        l10n.chemistryStyleBestForBasicGk,
      ),
    ];

class ChemistryStylesPage extends StatelessWidget {
  const ChemistryStylesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: AppAppBar(title: l10n.mechanicsChemistryStylesLabel),
      body: AppBackground(
        dense: true,
        child: ListView(
          children: <Widget>[
            GuideParagraph(l10n.chemistryStylesIntroParagraph),
            GuideHeading(l10n.chemistryStylesHeadingAll),
            for (final style in _styles(l10n))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(style.name, style: context.textStyles.titleSmall),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        style.boosts,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        style.bestFor,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
