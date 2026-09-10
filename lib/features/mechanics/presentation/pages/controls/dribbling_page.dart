import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/mechanics/presentation/widgets/guide_widgets.dart';
import 'package:flutter/material.dart';

class _SkillMove {
  const _SkillMove(this.name, this.control);

  final String name;
  final String control;
}

/// Skill Moves por estrela: referência rápida pra consultar durante o jogo,
/// nunca parágrafo. Seleção curada (não é a lista completa de ~90
/// movimentos) das ações mais úteis de cada faixa -- comandos idênticos em
/// PlayStation e Xbox/PC no analógico direito. Resumido a partir de
/// pesquisa (FIFPlay), nunca copiado literalmente.
const Map<int, List<_SkillMove>> _kMovesByStar = <int, List<_SkillMove>>{
  1: <_SkillMove>[
    _SkillMove('Elástico simples pro lado', 'Segurar L1+R1 + direção'),
    _SkillMove('Chapéu (Flick Up)', 'R3'),
    _SkillMove('Giro de corpo pra frente', 'Segurar L1+R1 + esquerdo p/ baixo'),
  ],
  2: <_SkillMove>[
    _SkillMove('Pedalada (Stepover) direita', 'Girar direito ↑→'),
    _SkillMove('Pedalada (Stepover) esquerda', 'Girar direito ↑←'),
    _SkillMove('Corta-luz (Ball Roll) direita', 'Segurar direito →'),
    _SkillMove('Corta-luz (Ball Roll) esquerda', 'Segurar direito ←'),
    _SkillMove('Puxada de bola (Drag Back)', 'L2+R2 + flick esquerdo ↓'),
  ],
  3: <_SkillMove>[
    _SkillMove('Roleta direita', 'Girar direito ↓ até ←'),
    _SkillMove('Roleta esquerda', 'Girar direito ↓ até →'),
    _SkillMove('Finta e vai pra direita', 'Girar direito ←↓→'),
    _SkillMove('Finta e vai pra esquerda', 'Girar direito →↓←'),
    _SkillMove(
      'Corte de calcanhar correndo',
      'Segurar L2 + ■/○ então X + esquerdo',
    ),
  ],
  4: <_SkillMove>[
    _SkillMove('Arco-íris simples', 'Flick direito ↓↑↑'),
    _SkillMove('Giro pra esquerda', 'Segurar R2+R1 + girar direito ↖'),
    _SkillMove('Giro pra direita', 'Segurar R2+R1 + girar direito ↗'),
    _SkillMove('Fake de passe', 'Segurar R2 + ■/○ então X'),
    _SkillMove('Corte com corta-luz', 'Segurar direito ← + esquerdo →'),
  ],
  5: <_SkillMove>[
    _SkillMove('Elástico', 'Direito → girar ↓←'),
    _SkillMove('Elástico invertido', 'Direito ← girar ↓→'),
    _SkillMove('Arco-íris avançado', 'Flick direito ↓ segurar ↑↑'),
    _SkillMove('Sombrero (chapéu em cima do marcador)', 'Flick direito ↑↑↓'),
    _SkillMove('Rabona fake', 'Segurar L2 + ■/○ então X + esquerdo ↓'),
  ],
};

class DribblingPage extends StatelessWidget {
  const DribblingPage({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppAppBar(title: context.l10n.controlsDribblingLabel),
    body: AppBackground(
      dense: true,
      child: ListView(
        children: <Widget>[
          const GuideParagraph(
            'Cada jogador tem uma nota de Skill Moves (1 a 5 estrelas) que '
            'define quais desses movimentos ele consegue fazer. Comandos '
            'usam o analógico direito e são iguais em PlayStation e '
            'Xbox/PC.',
          ),
          for (final star in _kMovesByStar.keys.toList()..sort()) ...<Widget>[
            GuideHeading(
              '${'★' * star} $star ${star == 1 ? 'estrela' : 'estrelas'}',
            ),
            for (final move in _kMovesByStar[star]!)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          move.name,
                          style: context.textStyles.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        move.control,
                        textAlign: TextAlign.end,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          const GuideHeading('Outros comandos de drible'),
          const GuideControlHeaderRow(),
          const GuideControlRow(
            action: 'Corrida controlada',
            playstation: 'Segurar R1 + direção',
            xbox: 'Segurar RB + direção',
          ),
          const GuideControlRow(
            action: 'Proteger a bola',
            playstation: 'Segurar L2',
            xbox: 'Segurar LT',
          ),
          const GuideControlRow(
            action: 'Toque de esforço',
            playstation: 'R1 + flick direito',
            xbox: 'RB + flick direito',
          ),
          const GuideControlRow(
            action: 'Fake de chute',
            playstation: '◯ depois ✕ + direção',
            xbox: 'B depois A + direção',
          ),
          const GuideHeading('Ideias pra aplicar'),
          const GuideBulletList(<String>[
            'Um drible bom reage ao movimento do defensor -- floreio sem '
                'motivo costuma facilitar perder a bola.',
            'Mude de velocidade em vez de correr sempre no talo: normal '
                'perto do defensor, corrida controlada pra se aproximar, '
                'sprint só quando o espaço já está aberto.',
            'Crie espaço primeiro, acelere depois: mude de direção ou '
                'faça um drible simples, espere o marcador se comprometer, '
                'só então acelere pro espaço livre.',
          ]),
        ],
      ),
    ),
  );
}
