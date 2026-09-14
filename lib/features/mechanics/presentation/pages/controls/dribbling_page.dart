import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/mechanics/presentation/widgets/guide_widgets.dart';
import 'package:fifa_queue/l10n/generated/app_localizations.dart';
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
/// pesquisa (FIFPlay), nunca copiado literalmente. Nomes/controles vem de
/// l10n (ver _movesByStar) -- so os proprios botoes/setas ficam fixos.
Map<int, List<_SkillMove>> _movesByStar(AppLocalizations l10n) =>
    <int, List<_SkillMove>>{
      1: <_SkillMove>[
        _SkillMove(
          l10n.controlsDribblingSkillName1,
          l10n.controlsDribblingSkillControl1,
        ),
        _SkillMove(
          l10n.controlsDribblingSkillName2,
          l10n.controlsDribblingSkillControl2,
        ),
        _SkillMove(
          l10n.controlsDribblingSkillName3,
          l10n.controlsDribblingSkillControl3,
        ),
      ],
      2: <_SkillMove>[
        _SkillMove(
          l10n.controlsDribblingSkillName4,
          l10n.controlsDribblingSkillControl4,
        ),
        _SkillMove(
          l10n.controlsDribblingSkillName5,
          l10n.controlsDribblingSkillControl5,
        ),
        _SkillMove(
          l10n.controlsDribblingSkillName6,
          l10n.controlsDribblingSkillControl6,
        ),
        _SkillMove(
          l10n.controlsDribblingSkillName7,
          l10n.controlsDribblingSkillControl7,
        ),
        _SkillMove(
          l10n.controlsDribblingSkillName8,
          l10n.controlsDribblingSkillControl8,
        ),
      ],
      3: <_SkillMove>[
        _SkillMove(
          l10n.controlsDribblingSkillName9,
          l10n.controlsDribblingSkillControl9,
        ),
        _SkillMove(
          l10n.controlsDribblingSkillName10,
          l10n.controlsDribblingSkillControl10,
        ),
        _SkillMove(
          l10n.controlsDribblingSkillName11,
          l10n.controlsDribblingSkillControl11,
        ),
        _SkillMove(
          l10n.controlsDribblingSkillName12,
          l10n.controlsDribblingSkillControl12,
        ),
        _SkillMove(
          l10n.controlsDribblingSkillName13,
          l10n.controlsDribblingSkillControl13,
        ),
      ],
      4: <_SkillMove>[
        _SkillMove(
          l10n.controlsDribblingSkillName14,
          l10n.controlsDribblingSkillControl14,
        ),
        _SkillMove(
          l10n.controlsDribblingSkillName15,
          l10n.controlsDribblingSkillControl15,
        ),
        _SkillMove(
          l10n.controlsDribblingSkillName16,
          l10n.controlsDribblingSkillControl16,
        ),
        _SkillMove(
          l10n.controlsDribblingSkillName17,
          l10n.controlsDribblingSkillControl17,
        ),
        _SkillMove(
          l10n.controlsDribblingSkillName18,
          l10n.controlsDribblingSkillControl18,
        ),
      ],
      5: <_SkillMove>[
        _SkillMove(
          l10n.controlsDribblingSkillName19,
          l10n.controlsDribblingSkillControl19,
        ),
        _SkillMove(
          l10n.controlsDribblingSkillName20,
          l10n.controlsDribblingSkillControl20,
        ),
        _SkillMove(
          l10n.controlsDribblingSkillName21,
          l10n.controlsDribblingSkillControl21,
        ),
        _SkillMove(
          l10n.controlsDribblingSkillName22,
          l10n.controlsDribblingSkillControl22,
        ),
        _SkillMove(
          l10n.controlsDribblingSkillName23,
          l10n.controlsDribblingSkillControl23,
        ),
      ],
    };

class DribblingPage extends StatelessWidget {
  const DribblingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final movesByStar = _movesByStar(l10n);

    return AppScaffold(
      appBar: AppAppBar(title: l10n.controlsDribblingLabel),
      body: AppBackground(
        dense: true,
        child: ListView(
          children: <Widget>[
            GuideParagraph(l10n.controlsDribblingIntroParagraph),
            for (final star in movesByStar.keys.toList()..sort()) ...<Widget>[
              GuideHeading(
                '${'★' * star} $star ${l10n.controlsDribblingStarWord(star)}',
              ),
              for (final move in movesByStar[star]!)
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
            GuideHeading(l10n.controlsDribblingHeadingOtherControls),
            const GuideControlHeaderRow(),
            GuideControlRow(
              action: l10n.controlsDribblingAction1,
              playstation: l10n.controlsDribblingPs1,
              xbox: l10n.controlsDribblingXbox1,
            ),
            GuideControlRow(
              action: l10n.controlsDribblingAction2,
              playstation: l10n.controlsDribblingPs2,
              xbox: l10n.controlsDribblingXbox2,
            ),
            GuideControlRow(
              action: l10n.controlsDribblingAction3,
              playstation: l10n.controlsDribblingPs3,
              xbox: l10n.controlsDribblingXbox3,
            ),
            GuideControlRow(
              action: l10n.controlsDribblingAction4,
              playstation: l10n.controlsDribblingPs4,
              xbox: l10n.controlsDribblingXbox4,
            ),
            GuideHeading(l10n.controlsDribblingHeadingIdeas),
            GuideBulletList(<String>[
              l10n.controlsDribblingBullet1,
              l10n.controlsDribblingBullet2,
              l10n.controlsDribblingBullet3,
            ]),
          ],
        ),
      ),
    );
  }
}
