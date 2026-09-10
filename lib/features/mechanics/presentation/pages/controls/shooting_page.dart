import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/mechanics/presentation/widgets/guide_widgets.dart';
import 'package:flutter/material.dart';

/// Guia de finalização: comandos reais do FC 27, resumido a partir de
/// pesquisa (FIFPlay), nunca copiado literalmente.
class ShootingPage extends StatelessWidget {
  const ShootingPage({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppAppBar(title: context.l10n.controlsShootingLabel),
    body: AppBackground(
      dense: true,
      child: ListView(
        children: <Widget>[
          const GuideHeading('Controles'),
          const GuideControlHeaderRow(),
          const GuideControlRow(
            action: 'Chute normal / voleio / cabeceio',
            playstation: '◯',
            xbox: 'B',
          ),
          const GuideControlRow(
            action: 'Chute rasteiro e forte',
            playstation: '◯, depois ◯ de novo ao carregar',
            xbox: 'B, depois B de novo ao carregar',
          ),
          const GuideControlRow(
            action: 'Cavadinha',
            playstation: 'L1 + ◯',
            xbox: 'LB + B',
          ),
          const GuideControlRow(
            action: 'Chute de efeito',
            playstation: 'R1 + ◯',
            xbox: 'RB + B',
          ),
          const GuideControlRow(
            action: 'Chute de efeito rasteiro',
            playstation: 'R1 + ◯, depois ◯ de novo',
            xbox: 'RB + B, depois B de novo',
          ),
          const GuideControlRow(
            action: 'Chute de potência',
            playstation: 'L1 + R1 + ◯',
            xbox: 'LB + RB + B',
          ),
          const GuideControlRow(
            action: 'Chute de potência rasteiro',
            playstation: 'L1 + R1 + ◯, depois ◯ de novo',
            xbox: 'LB + RB + B, depois B de novo',
          ),
          const GuideControlRow(
            action: 'Chute de estilo (trivela, bicicleta...)',
            playstation: 'L2 + ◯',
            xbox: 'LT + B',
          ),
          const GuideControlRow(
            action: 'Fake de chute',
            playstation: '◯ depois ✕ + direção',
            xbox: 'B depois A + direção',
          ),
          const GuideControlRow(
            action: 'Cancelar chute',
            playstation: 'L2 + R2 durante a animação',
            xbox: 'LT + RT durante a animação',
          ),
          const GuideHeading('Quando usar cada um'),
          const GuideBulletList(<String>[
            'Chute normal: opção mais versátil, funciona bem na maioria '
                'das situações dentro da área.',
            'Chute rasteiro: bom pra bater cruzado ou no goleiro '
                'adiantado, rasteiro nos cantos.',
            'Chute de efeito: prioriza colocação e curva -- ótimo cortando '
                'pra dentro pelo lado e mirando o canto mais longe.',
            'Chute de potência: exige mais tempo e espaço livre, melhor '
                'fora da área do que dentro dela.',
            'Cavadinha: quando o goleiro sai da linha e sobra espaço por '
                'cima dele.',
            'Chute de estilo: mais imprevisível, deixa a animação decidir '
                'entre bicicleta, carrinho de fora ou outro floreio '
                'conforme a posição do jogador.',
            'Fake de chute: engana o goleiro ou o defensor mudando de '
                'direção sem finalizar de verdade.',
          ]),
          const GuideHeading('Potência e mira'),
          const GuideParagraph(
            'Quanto mais tempo segura o botão de chute, mais força o '
            'chute recebe. Perto do gol, potência baixa ou média costuma '
            'funcionar melhor que o chute no talo -- excesso de força é '
            'mais difícil de controlar de perto.',
          ),
        ],
      ),
    ),
  );
}
