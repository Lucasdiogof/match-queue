import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/mechanics/presentation/widgets/guide_widgets.dart';
import 'package:flutter/material.dart';

/// Explicação de como Chemistry funciona no FC 27 -- conteúdo estático,
/// resumido a partir de pesquisa (FIFPlay), nunca copiado literalmente.
class ChemistryPage extends StatelessWidget {
  const ChemistryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: AppAppBar(title: l10n.mechanicsChemistryLabel),
      body: AppBackground(
        dense: true,
        child: ListView(
          children: <Widget>[
            GuideParagraph(l10n.chemistryIntroParagraph),
            GuideHeading(l10n.chemistryHeadingHowEarned),
            GuideParagraph(l10n.chemistryHowEarnedParagraph),
            GuideBulletList(<String>[
              l10n.chemistryHowEarnedBullet1,
              l10n.chemistryHowEarnedBullet2,
              l10n.chemistryHowEarnedBullet3,
              l10n.chemistryHowEarnedBullet4,
            ]),
            GuideHeading(l10n.chemistryHeadingPosition),
            GuideParagraph(l10n.chemistryPositionParagraph),
            GuideHeading(l10n.chemistryHeadingClubLeagueNation),
            GuideParagraph(l10n.chemistryClubLeagueNationParagraph),
            GuideBulletList(<String>[
              l10n.chemistryClubLeagueNationBullet1,
              l10n.chemistryClubLeagueNationBullet2,
              l10n.chemistryClubLeagueNationBullet3,
              l10n.chemistryClubLeagueNationBullet4,
              l10n.chemistryClubLeagueNationBullet5,
              l10n.chemistryClubLeagueNationBullet6,
              l10n.chemistryClubLeagueNationBullet7,
              l10n.chemistryClubLeagueNationBullet8,
              l10n.chemistryClubLeagueNationBullet9,
            ]),
            GuideHeading(l10n.chemistryHeadingManager),
            GuideParagraph(l10n.chemistryManagerParagraph),
            GuideHeading(l10n.chemistryHeadingIconsHeroes),
            GuideParagraph(l10n.chemistryIconsHeroesParagraph),
            GuideHeading(l10n.chemistryHeadingMenWomen),
            GuideParagraph(l10n.chemistryMenWomenParagraph),
            GuideHeading(l10n.chemistryHeadingSubs),
            GuideParagraph(l10n.chemistrySubsParagraph),
          ],
        ),
      ),
    );
  }
}
