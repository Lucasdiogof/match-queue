import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/mechanics/presentation/widgets/guide_widgets.dart';
import 'package:flutter/material.dart';

/// Guia de finalização: comandos reais do FC 27, resumido a partir de
/// pesquisa (FIFPlay), nunca copiado literalmente. Botões em si (◯, B, L1...)
/// nao precisam de l10n -- sao os mesmos em qualquer idioma -- so as
/// palavras junto deles (depois, durante...) e os nomes das acoes passam
/// por l10n.
class ShootingPage extends StatelessWidget {
  const ShootingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: AppAppBar(title: l10n.controlsShootingLabel),
      body: AppBackground(
        dense: true,
        child: ListView(
          children: <Widget>[
            GuideHeading(l10n.controlsHeadingControls),
            const GuideControlHeaderRow(),
            GuideControlRow(
              action: l10n.controlsShootingAction1,
              playstation: '◯',
              xbox: 'B',
            ),
            GuideControlRow(
              action: l10n.controlsShootingAction2,
              playstation: l10n.controlsShootingPs2,
              xbox: l10n.controlsShootingXbox2,
            ),
            GuideControlRow(
              action: l10n.controlsShootingAction3,
              playstation: 'L1 + ◯',
              xbox: 'LB + B',
            ),
            GuideControlRow(
              action: l10n.controlsShootingAction4,
              playstation: 'R1 + ◯',
              xbox: 'RB + B',
            ),
            GuideControlRow(
              action: l10n.controlsShootingAction5,
              playstation: l10n.controlsShootingPs5,
              xbox: l10n.controlsShootingXbox5,
            ),
            GuideControlRow(
              action: l10n.controlsShootingAction6,
              playstation: 'L1 + R1 + ◯',
              xbox: 'LB + RB + B',
            ),
            GuideControlRow(
              action: l10n.controlsShootingAction7,
              playstation: l10n.controlsShootingPs7,
              xbox: l10n.controlsShootingXbox7,
            ),
            GuideControlRow(
              action: l10n.controlsShootingAction8,
              playstation: 'L2 + ◯',
              xbox: 'LT + B',
            ),
            GuideControlRow(
              action: l10n.controlsShootingAction9,
              playstation: l10n.controlsShootingPs9,
              xbox: l10n.controlsShootingXbox9,
            ),
            GuideControlRow(
              action: l10n.controlsShootingAction10,
              playstation: l10n.controlsShootingPs10,
              xbox: l10n.controlsShootingXbox10,
            ),
            GuideHeading(l10n.controlsShootingHeadingWhenToUse),
            GuideBulletList(<String>[
              l10n.controlsShootingBullet1,
              l10n.controlsShootingBullet2,
              l10n.controlsShootingBullet3,
              l10n.controlsShootingBullet4,
              l10n.controlsShootingBullet5,
              l10n.controlsShootingBullet6,
              l10n.controlsShootingBullet7,
            ]),
            GuideHeading(l10n.controlsShootingHeadingPower),
            GuideParagraph(l10n.controlsShootingPowerParagraph),
          ],
        ),
      ),
    );
  }
}
