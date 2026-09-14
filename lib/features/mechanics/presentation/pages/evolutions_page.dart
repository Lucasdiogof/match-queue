import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/mechanics/presentation/widgets/guide_widgets.dart';
import 'package:flutter/material.dart';

/// Evolutions muda de programa em programa dentro do próprio Ultimate
/// Team (cada Evolution tem requisitos, níveis e prazo de validade
/// próprios) -- não temos nenhuma fonte que acompanhe isso ao vivo. Por
/// pedido explícito do dono do produto, esta tela fica só como explicação
/// de conceito, nunca fingindo ser uma lista atualizada de programas em
/// vigor.
class EvolutionsPage extends StatelessWidget {
  const EvolutionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: AppAppBar(title: l10n.mechanicsEvolutionsLabel),
      body: AppBackground(
        dense: true,
        child: ListView(
          children: <Widget>[
            GuideParagraph(l10n.evolutionsIntroParagraph),
            GuideHeading(l10n.evolutionsHeadingWhatChanges),
            GuideBulletList(<String>[
              l10n.evolutionsWhatChangesBullet1,
              l10n.evolutionsWhatChangesBullet2,
              l10n.evolutionsWhatChangesBullet3,
              l10n.evolutionsWhatChangesBullet4,
              l10n.evolutionsWhatChangesBullet5,
              l10n.evolutionsWhatChangesBullet6,
            ]),
            GuideHeading(l10n.evolutionsHeadingHowItWorks),
            GuideBulletList(<String>[
              l10n.evolutionsHowItWorksBullet1,
              l10n.evolutionsHowItWorksBullet2,
              l10n.evolutionsHowItWorksBullet3,
              l10n.evolutionsHowItWorksBullet4,
              l10n.evolutionsHowItWorksBullet5,
            ]),
            GuideHeading(l10n.evolutionsHeadingWhyNoList),
            GuideParagraph(l10n.evolutionsWhyNoListParagraph),
          ],
        ),
      ),
    );
  }
}
