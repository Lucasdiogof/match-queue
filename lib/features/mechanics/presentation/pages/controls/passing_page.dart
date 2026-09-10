import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/mechanics/presentation/widgets/guide_widgets.dart';
import 'package:flutter/material.dart';

/// Guia de passe: comandos reais do FC 27, resumido a partir de pesquisa
/// (FIFPlay), nunca copiado literalmente.
class PassingPage extends StatelessWidget {
  const PassingPage({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppAppBar(title: context.l10n.controlsPassingLabel),
    body: AppBackground(
      dense: true,
      child: ListView(
        children: <Widget>[
          const GuideHeading('Passe curto (rasteiro)'),
          const GuideControlHeaderRow(),
          const GuideControlRow(
            action: 'Passe rasteiro',
            playstation: '✕',
            xbox: 'A',
          ),
          const GuideControlRow(
            action: 'Passe rasteiro elevado',
            playstation: '✕ + ✕',
            xbox: 'A + A',
          ),
          const GuideControlRow(
            action: 'Passe rasteiro forte',
            playstation: 'R1 + ✕',
            xbox: 'RB + A',
          ),
          const GuideControlRow(
            action: 'Passe de efeito',
            playstation: 'L2 + ✕',
            xbox: 'LT + A',
          ),
          const GuideControlRow(
            action: 'Passe rasteiro de precisão (com curva)',
            playstation: 'L2 + R1 + ✕',
            xbox: 'LT + RB + A',
          ),
          const GuideHeading('Passe em profundidade (through pass)'),
          const GuideControlRow(
            action: 'Passe em profundidade',
            playstation: '△',
            xbox: 'Y',
          ),
          const GuideControlRow(
            action: 'Passe em profundidade elevado',
            playstation: '△ + △',
            xbox: 'Y + Y',
          ),
          const GuideControlRow(
            action: 'Passe em profundidade de precisão',
            playstation: 'R1 + △',
            xbox: 'RB + Y',
          ),
          const GuideControlRow(
            action: 'Passe em profundidade lobado',
            playstation: 'L1 + △',
            xbox: 'LB + Y',
          ),
          const GuideControlRow(
            action: 'Passe em profundidade forte',
            playstation: 'L1 + R1 + △',
            xbox: 'LB + RB + Y',
          ),
          const GuideControlRow(
            action: 'Passe em profundidade de efeito',
            playstation: 'L2 + △',
            xbox: 'LT + Y',
          ),
          const GuideHeading('Lançamento e cruzamento'),
          const GuideControlRow(
            action: 'Lançamento / cruzamento',
            playstation: '□',
            xbox: 'X',
          ),
          const GuideControlRow(
            action: 'Cruzamento rasteiro',
            playstation: '□ + □',
            xbox: 'X + X',
          ),
          const GuideControlRow(
            action: 'Lançamento de precisão',
            playstation: 'R1 + □',
            xbox: 'RB + X',
          ),
          const GuideControlRow(
            action: 'Lançamento forte',
            playstation: 'L1 + R1 + □',
            xbox: 'LB + RB + X',
          ),
          const GuideControlRow(
            action: 'Cruzamento rasteiro forte',
            playstation: 'L1 + R1 + □ + □',
            xbox: 'LB + RB + X + X',
          ),
          const GuideControlRow(
            action: 'Lançamento bem alto',
            playstation: 'L1 + □',
            xbox: 'LB + X',
          ),
          const GuideControlRow(
            action: 'Lançamento de efeito',
            playstation: 'L2 + □',
            xbox: 'LT + X',
          ),
          const GuideHeading('Outros'),
          const GuideControlRow(
            action: 'Toque e vai (Pass and Go)',
            playstation: 'L1 + ✕',
            xbox: 'LB + A',
          ),
          const GuideControlRow(
            action: 'Fake de passe',
            playstation: '□ depois ✕ + direção',
            xbox: 'X depois A + direção',
          ),
          const GuideHeading('Ideias pra aplicar'),
          const GuideBulletList(<String>[
            'Passe rasteiro mantém a posse no meio-campo; passe em '
                'profundidade serve pra jogadores fazendo corrida por '
                'trás da defesa.',
            'Lançamento troca o jogo rápido pro lado aberto do campo.',
            'Passe forte (driven) sai mais rápido sob pressão, mas com '
                'menos controle do que o de precisão.',
            'Quanto mais tempo segura o botão, mais força o passe recebe '
                '-- combinar o tipo certo com a força certa importa tanto '
                'quanto escolher o companheiro certo.',
          ]),
        ],
      ),
    ),
  );
}
