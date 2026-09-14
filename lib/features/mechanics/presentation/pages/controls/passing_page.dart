import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/mechanics/presentation/widgets/guide_widgets.dart';
import 'package:flutter/material.dart';

/// Guia de passe: comandos reais do FC 27, resumido a partir de pesquisa
/// (FIFPlay), nunca copiado literalmente. Botões em si (✕, △, □, A, Y, X...)
/// nao precisam de l10n -- so os nomes das acoes e as poucas linhas com
/// palavra junto do botao.
class PassingPage extends StatelessWidget {
  const PassingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: AppAppBar(title: l10n.controlsPassingLabel),
      body: AppBackground(
        dense: true,
        child: ListView(
          children: <Widget>[
            GuideHeading(l10n.controlsPassingHeadingShort),
            const GuideControlHeaderRow(),
            GuideControlRow(
              action: l10n.controlsPassingAction1,
              playstation: '✕',
              xbox: 'A',
            ),
            GuideControlRow(
              action: l10n.controlsPassingAction2,
              playstation: '✕ + ✕',
              xbox: 'A + A',
            ),
            GuideControlRow(
              action: l10n.controlsPassingAction3,
              playstation: 'R1 + ✕',
              xbox: 'RB + A',
            ),
            GuideControlRow(
              action: l10n.controlsPassingAction4,
              playstation: 'L2 + ✕',
              xbox: 'LT + A',
            ),
            GuideControlRow(
              action: l10n.controlsPassingAction5,
              playstation: 'L2 + R1 + ✕',
              xbox: 'LT + RB + A',
            ),
            GuideHeading(l10n.controlsPassingHeadingThrough),
            GuideControlRow(
              action: l10n.controlsPassingAction6,
              playstation: '△',
              xbox: 'Y',
            ),
            GuideControlRow(
              action: l10n.controlsPassingAction7,
              playstation: '△ + △',
              xbox: 'Y + Y',
            ),
            GuideControlRow(
              action: l10n.controlsPassingAction8,
              playstation: 'R1 + △',
              xbox: 'RB + Y',
            ),
            GuideControlRow(
              action: l10n.controlsPassingAction9,
              playstation: 'L1 + △',
              xbox: 'LB + Y',
            ),
            GuideControlRow(
              action: l10n.controlsPassingAction10,
              playstation: 'L1 + R1 + △',
              xbox: 'LB + RB + Y',
            ),
            GuideControlRow(
              action: l10n.controlsPassingAction11,
              playstation: 'L2 + △',
              xbox: 'LT + Y',
            ),
            GuideHeading(l10n.controlsPassingHeadingCrossing),
            GuideControlRow(
              action: l10n.controlsPassingAction12,
              playstation: '□',
              xbox: 'X',
            ),
            GuideControlRow(
              action: l10n.controlsPassingAction13,
              playstation: '□ + □',
              xbox: 'X + X',
            ),
            GuideControlRow(
              action: l10n.controlsPassingAction14,
              playstation: 'R1 + □',
              xbox: 'RB + X',
            ),
            GuideControlRow(
              action: l10n.controlsPassingAction15,
              playstation: 'L1 + R1 + □',
              xbox: 'LB + RB + X',
            ),
            GuideControlRow(
              action: l10n.controlsPassingAction16,
              playstation: 'L1 + R1 + □ + □',
              xbox: 'LB + RB + X + X',
            ),
            GuideControlRow(
              action: l10n.controlsPassingAction17,
              playstation: 'L1 + □',
              xbox: 'LB + X',
            ),
            GuideControlRow(
              action: l10n.controlsPassingAction18,
              playstation: 'L2 + □',
              xbox: 'LT + X',
            ),
            GuideHeading(l10n.controlsPassingHeadingOthers),
            GuideControlRow(
              action: l10n.controlsPassingAction19,
              playstation: 'L1 + ✕',
              xbox: 'LB + A',
            ),
            GuideControlRow(
              action: l10n.controlsPassingAction20,
              playstation: l10n.controlsPassingPs20,
              xbox: l10n.controlsPassingXbox20,
            ),
            GuideHeading(l10n.controlsPassingHeadingIdeas),
            GuideBulletList(<String>[
              l10n.controlsPassingBullet1,
              l10n.controlsPassingBullet2,
              l10n.controlsPassingBullet3,
              l10n.controlsPassingBullet4,
            ]),
          ],
        ),
      ),
    );
  }
}
