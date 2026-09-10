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
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppAppBar(title: context.l10n.mechanicsEvolutionsLabel),
    body: AppBackground(
      dense: true,
      child: ListView(
        children: <Widget>[
          const GuideParagraph(
            'Evolutions são programas de desenvolvimento pra cartas '
            'elegíveis do Ultimate Team: em vez de depender só de novas '
            'cartas promocionais, dá pra evoluir jogadores que você já '
            'tem completando uma série de desafios.',
          ),
          const GuideHeading('O que uma Evolution pode mudar'),
          const GuideBulletList(<String>[
            'Atributos (ritmo, finalização, passe, drible, defesa, '
                'físico ou de goleiro).',
            'PlayStyles e PlayStyles+.',
            'Posição, incluindo posições alternativas novas.',
            'Roles e a familiaridade com eles.',
            'Skill Moves e pé fraco.',
            'Visual da carta (design, fundo, tema).',
          ]),
          const GuideHeading('Como funciona, em linhas gerais'),
          const GuideBulletList(<String>[
            'Cada Evolution tem requisitos de entrada (rating máximo, '
                'posição, atributos, raridade, liga, nação, PlayStyles '
                'já existentes etc.) -- nem toda carta é elegível.',
            'O programa é dividido em níveis; cada nível tem seus '
                'próprios desafios (jogar partidas, vencer, marcar, dar '
                'assistência, manter o gol invicto...).',
            'Alguns níveis oferecem mais de uma recompensa pra escolher, '
                'em vez de um único caminho fixo pra todo mundo.',
            'É possível remover a última Evolution aplicada (ou todas de '
                'uma vez), o que devolve o status de negociável a uma '
                'carta que tinha vindo do mercado.',
            'A mesma carta pode encadear várias Evolutions ao longo da '
                'temporada, desde que siga sendo elegível pra cada uma.',
          ]),
          const GuideHeading('Por que esta tela não lista programas ativos'),
          const GuideParagraph(
            'Os programas de Evolution mudam com frequência dentro do '
            'próprio ciclo de Ultimate Team, e não temos hoje uma fonte '
            'que acompanhe isso de forma confiável e atualizada. Preferimos '
            'explicar o conceito de verdade a mostrar uma lista estática '
            'se passando por informação ao vivo.',
          ),
        ],
      ),
    ),
  );
}
