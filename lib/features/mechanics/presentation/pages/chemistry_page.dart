import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/mechanics/presentation/widgets/guide_widgets.dart';
import 'package:flutter/material.dart';

/// Explicação de como Chemistry funciona no FC 27 -- conteúdo estático,
/// resumido a partir de pesquisa (FIFPlay), nunca copiado literalmente.
///
/// PT-only por enquanto: é conteúdo de referência extenso, não chrome de
/// app -- ver nota de tradução pendente no handoff desta etapa.
class ChemistryPage extends StatelessWidget {
  const ChemistryPage({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppAppBar(title: context.l10n.mechanicsChemistryLabel),
    body: AppBackground(
      dense: true,
      child: ListView(
        children: <Widget>[
          const GuideParagraph(
            'Chemistry define o quanto o Chemistry Style aplicado numa '
            'carta realmente entrega. Não é mais um sistema de "linhas" '
            'entre jogadores adjacentes como em FIFAs antigos -- é '
            'construído em cima da escalação titular inteira.',
          ),
          const GuideHeading('Como cada jogador ganha Chemistry'),
          const GuideParagraph(
            'Todo titular pode ter de 0 a 3 pontos de Chemistry. O time '
            'inteiro soma até 33 pontos de Squad Chemistry.',
          ),
          const GuideBulletList(<String>[
            '0 de Chemistry: nenhum bônus de Chemistry Style, mas o '
                'jogador continua com os atributos normais da carta.',
            '1 de Chemistry: bônus pequeno do Chemistry Style aplicado.',
            '2 de Chemistry: bônus médio.',
            '3 de Chemistry: bônus máximo.',
          ]),
          const GuideHeading('Pré-requisito: posição preferida'),
          const GuideParagraph(
            'Um jogador só ganha e contribui Chemistry se estiver numa '
            'das posições preferidas dele na formação. Fora disso, fica '
            'com 0 de Chemistry e não conta pros totais de clube, liga ou '
            'nação -- mesmo estando na escalação.',
          ),
          const GuideHeading('Clube, liga e nação/região'),
          const GuideParagraph(
            'Os titulares contribuem juntos pros totais de clube, liga e '
            'nação/região do time inteiro -- não precisa mais estar do '
            'lado de outro jogador igual antes.',
          ),
          const GuideBulletList(<String>[
            '2 jogadores do mesmo clube: +1 de Chemistry de clube.',
            '4 jogadores do mesmo clube: +2.',
            '7 jogadores do mesmo clube: +3.',
            '2 jogadores da mesma nação/região: +1.',
            '5 jogadores da mesma nação/região: +2.',
            '8 jogadores da mesma nação/região: +3.',
            '3 jogadores da mesma liga: +1.',
            '5 jogadores da mesma liga: +2.',
            '8 jogadores da mesma liga: +3.',
          ]),
          const GuideHeading('Técnico'),
          const GuideParagraph(
            'O técnico pode dar +1 de Chemistry extra a um jogador que '
            'compartilhe liga ou nação/região com ele, até o máximo de 3.',
          ),
          const GuideHeading('Ícones e Heróis'),
          const GuideParagraph(
            'Ícones e Heróis sempre têm Chemistry máximo (3) quando jogam '
            'na posição certa. Ícones contam pra todas as ligas '
            'representadas no time, além da própria nação; Heróis dão '
            'Chemistry extra pra própria liga e nação. Isso facilita muito '
            'montar times híbridos.',
          ),
          const GuideHeading('Masculino e feminino'),
          const GuideParagraph(
            'Jogadores e jogadoras contribuem Chemistry juntos quando '
            'compartilham nação/região, ou quando os clubes masculino e '
            'feminino são afiliados -- mas não se conectam pela liga.',
          ),
          const GuideHeading('Reservas'),
          const GuideParagraph(
            'Só o time titular conta pro Squad Chemistry. Reservas e quem '
            'entra durante a partida não geram Chemistry nem recebem bônus '
            'de Chemistry Style.',
          ),
        ],
      ),
    ),
  );
}
