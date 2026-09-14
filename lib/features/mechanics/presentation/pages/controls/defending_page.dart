import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/mechanics/presentation/widgets/guide_widgets.dart';
import 'package:flutter/material.dart';

/// Guia de defesa: comandos reais do FC 27, resumido a partir de pesquisa
/// (FIFPlay), nunca copiado literalmente. Controles e dicas separados,
/// como pedido. Botões em si (◯, □, L1...) nao precisam de l10n.
class DefendingPage extends StatelessWidget {
  const DefendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: AppAppBar(title: l10n.controlsDefendingLabel),
      body: AppBackground(
        dense: true,
        child: ListView(
          children: <Widget>[
            GuideHeading(l10n.controlsHeadingControls),
            const GuideControlHeaderRow(),
            GuideControlRow(
              action: l10n.controlsDefendingAction1,
              playstation: 'L1',
              xbox: 'LB',
            ),
            GuideControlRow(
              action: l10n.controlsDefendingAction2,
              playstation: l10n.controlsDefendingPs2,
              xbox: l10n.controlsDefendingXbox2,
            ),
            GuideControlRow(
              action: l10n.controlsDefendingAction3,
              playstation: l10n.controlsDefendingPs3,
              xbox: l10n.controlsDefendingXbox3,
            ),
            GuideControlRow(
              action: l10n.controlsDefendingAction4,
              playstation: '◯',
              xbox: 'B',
            ),
            GuideControlRow(
              action: l10n.controlsDefendingAction5,
              playstation: 'R1 + ◯',
              xbox: 'RB + B',
            ),
            GuideControlRow(
              action: l10n.controlsDefendingAction6,
              playstation: '□',
              xbox: 'X',
            ),
            GuideControlRow(
              action: l10n.controlsDefendingAction7,
              playstation: 'R1 + □',
              xbox: 'RB + X',
            ),
            GuideControlRow(
              action: l10n.controlsDefendingAction8,
              playstation: l10n.controlsDefendingPs8,
              xbox: l10n.controlsDefendingXbox8,
            ),
            GuideControlRow(
              action: l10n.controlsDefendingAction9,
              playstation: l10n.controlsDefendingPs9,
              xbox: l10n.controlsDefendingXbox9,
            ),
            GuideControlRow(
              action: l10n.controlsDefendingAction10,
              playstation: l10n.controlsDefendingPs10,
              xbox: l10n.controlsDefendingXbox10,
            ),
            GuideHeading(l10n.controlsDefendingHeadingTips),
            GuideBulletList(<String>[
              l10n.controlsDefendingBullet1,
              l10n.controlsDefendingBullet2,
              l10n.controlsDefendingBullet3,
              l10n.controlsDefendingBullet4,
              l10n.controlsDefendingBullet5,
              l10n.controlsDefendingBullet6,
            ]),
          ],
        ),
      ),
    );
  }
}
