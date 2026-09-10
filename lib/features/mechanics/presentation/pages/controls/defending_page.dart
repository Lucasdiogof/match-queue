import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/mechanics/presentation/widgets/guide_widgets.dart';
import 'package:flutter/material.dart';

/// Guia de defesa: comandos reais do FC 27, resumido a partir de pesquisa
/// (FIFPlay), nunca copiado literalmente. Controles e dicas separados,
/// como pedido.
class DefendingPage extends StatelessWidget {
  const DefendingPage({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppAppBar(title: context.l10n.controlsDefendingLabel),
    body: AppBackground(
      dense: true,
      child: ListView(
        children: <Widget>[
          const GuideHeading('Controles'),
          const GuideControlHeaderRow(),
          const GuideControlRow(
            action: 'Trocar de jogador',
            playstation: 'L1',
            xbox: 'LB',
          ),
          const GuideControlRow(
            action: 'Marcação (contain / jockey)',
            playstation: 'Segurar L2',
            xbox: 'Segurar LT',
          ),
          const GuideControlRow(
            action: 'Marcação em sprint',
            playstation: 'Segurar L2 + R2',
            xbox: 'Segurar LT + RT',
          ),
          const GuideControlRow(
            action: 'Carrinho em pé',
            playstation: '◯',
            xbox: 'B',
          ),
          const GuideControlRow(
            action: 'Carrinho em pé forte',
            playstation: 'R1 + ◯',
            xbox: 'RB + B',
          ),
          const GuideControlRow(
            action: 'Carrinho deslizante',
            playstation: '□',
            xbox: 'X',
          ),
          const GuideControlRow(
            action: 'Carrinho deslizante forte',
            playstation: 'R1 + □',
            xbox: 'RB + X',
          ),
          const GuideControlRow(
            action: 'Pedir pressão de um companheiro',
            playstation: 'Segurar R1',
            xbox: 'Segurar RB',
          ),
          const GuideControlRow(
            action: 'Pressão coletiva parcial',
            playstation: 'R1, depois segurar R1',
            xbox: 'RB, depois segurar RB',
          ),
          const GuideControlRow(
            action: 'Goleiro adiantar a linha',
            playstation: 'Segurar △',
            xbox: 'Segurar Y',
          ),
          const GuideHeading('Dicas'),
          const GuideBulletList(<String>[
            'Marcação (jockey) primeiro, carrinho depois: mantenha o '
                'defensor de frente pro atacante, reduza o espaço, e só '
                'tente o desarme quando a bola ficar exposta.',
            'Carrinho deslizante é opção de último recurso -- errar deixa '
                'o adversário livre ou pode virar falta, cartão ou '
                'pênalti.',
            'Troque de jogador manualmente em vez de sempre pegar o mais '
                'perto da bola: às vezes cobrir a linha de passe mais '
                'perigosa importa mais do que pressionar quem já está '
                'marcado.',
            'Não puxe o zagueiro pra frente sem necessidade -- isso abre '
                'espaço nas costas da defesa pra um passe em '
                'profundidade.',
            'Contra um contra-ataque, prioridade é atrasar o avanço (recuar '
                'protegendo o meio) e só então fechar o lance, dando tempo '
                'pros companheiros se recomporem.',
            'Ao defender cruzamento, não olhe só pro ponta -- cubra '
                'também quem chega no segundo pau.',
          ]),
        ],
      ),
    ),
  );
}
