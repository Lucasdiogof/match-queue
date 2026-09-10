import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/mechanics/presentation/widgets/guide_widgets.dart';
import 'package:flutter/material.dart';

class _ChemistryStyleInfo {
  const _ChemistryStyleInfo(this.name, this.boosts, this.bestFor);

  final String name;
  final String boosts;
  final String bestFor;
}

/// Chemistry Styles: item base de Ultimate Team (tecnicamente um
/// consumível), mas mantido em Mecânicas por decisão explícita do dono do
/// produto -- não duplicar em Consumíveis.
///
/// Nenhuma carta do nosso catálogo grava qual Chemistry Style está
/// aplicado (isso é escolha de squad do jogador, não dado da carta), então
/// esta tela é só o catálogo de estilos -- sem associação com cartas.
const List<_ChemistryStyleInfo> _kStyles = <_ChemistryStyleInfo>[
  _ChemistryStyleInfo(
    'Basic',
    'Boost equilibrado em vários atributos',
    'Uso geral',
  ),
  _ChemistryStyleInfo(
    'Sniper',
    'Finalização, Drible',
    'Finalizadores clínicos',
  ),
  _ChemistryStyleInfo('Finisher', 'Finalização, Físico', 'Atacantes de força'),
  _ChemistryStyleInfo('Deadeye', 'Finalização, Passe', 'Atacantes criativos'),
  _ChemistryStyleInfo(
    'Marksman',
    'Finalização, Drible, Físico',
    'Atacantes fortes',
  ),
  _ChemistryStyleInfo(
    'Hawk',
    'Ritmo, Finalização, Físico',
    'Atacantes rápidos',
  ),
  _ChemistryStyleInfo('Artist', 'Passe, Drible', 'Armadores'),
  _ChemistryStyleInfo('Architect', 'Passe, Físico', 'Meias recuados'),
  _ChemistryStyleInfo('Powerhouse', 'Passe, Defesa', 'Volantes'),
  _ChemistryStyleInfo(
    'Maestro',
    'Passe, Drible, Finalização',
    'Meias ofensivos',
  ),
  _ChemistryStyleInfo(
    'Engine',
    'Ritmo, Passe, Drible',
    'Meias box-to-box e pontas',
  ),
  _ChemistryStyleInfo('Sentinel', 'Defesa, Físico', 'Zagueiros'),
  _ChemistryStyleInfo('Guardian', 'Defesa, Drible', 'Laterais'),
  _ChemistryStyleInfo('Gladiator', 'Finalização, Defesa', 'Versáteis'),
  _ChemistryStyleInfo('Backbone', 'Passe, Defesa, Físico', 'Defensores'),
  _ChemistryStyleInfo(
    'Anchor',
    'Ritmo, Defesa, Físico',
    'Zagueiros e volantes',
  ),
  _ChemistryStyleInfo('Hunter', 'Ritmo, Finalização', 'Atacantes'),
  _ChemistryStyleInfo('Catalyst', 'Ritmo, Passe', 'Pontas e laterais'),
  _ChemistryStyleInfo('Shadow', 'Ritmo, Defesa', 'Defensores'),
  _ChemistryStyleInfo(
    'Wall',
    'Defesa (Mergulho, Reflexos, Reposição)',
    'Goleiros',
  ),
  _ChemistryStyleInfo(
    'Shield',
    'Defesa (Reposição, Reflexos, Velocidade)',
    'Goleiros',
  ),
  _ChemistryStyleInfo(
    'Cat',
    'Defesa (Reflexos, Velocidade, Posicionamento)',
    'Goleiros',
  ),
  _ChemistryStyleInfo(
    'Glove',
    'Defesa (Elasticidade, Mergulho, Posicionamento)',
    'Goleiros',
  ),
  _ChemistryStyleInfo(
    'Basic (GK)',
    'Boost equilibrado de goleiro',
    'Uso geral',
  ),
];

class ChemistryStylesPage extends StatelessWidget {
  const ChemistryStylesPage({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppAppBar(title: context.l10n.mechanicsChemistryStylesLabel),
    body: AppBackground(
      dense: true,
      child: ListView(
        children: <Widget>[
          const GuideParagraph(
            'Chemistry Style é um item que reforça atributos específicos '
            'de uma carta -- mas só entrega o bônus se a carta tiver '
            'Chemistry (0 de Chemistry = nenhum boost, não importa o '
            'estilo aplicado). Cada carta só pode ter um Chemistry Style '
            'ativo por vez; aplicar outro substitui o anterior.',
          ),
          const GuideHeading('Todos os estilos'),
          for (final style in _kStyles)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(style.name, style: context.textStyles.titleSmall),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      style.boosts,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      style.bestFor,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
