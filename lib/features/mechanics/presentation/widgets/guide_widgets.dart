import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Blocos reutilizáveis pras telas de conteúdo estático de Mecânicas e
/// Controles -- só leitura, sem estado, sem chamada de rede.
class GuideHeading extends StatelessWidget {
  const GuideHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
    child: Text(
      text.toUpperCase(),
      style: context.textStyles.labelSmall?.copyWith(
        color: context.colors.textTertiary,
        letterSpacing: 1.4,
      ),
    ),
  );
}

class GuideParagraph extends StatelessWidget {
  const GuideParagraph(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Text(
      text,
      style: context.textStyles.bodyMedium?.copyWith(
        color: context.colors.textSecondary,
      ),
    ),
  );
}

/// Uma linha de controle: ação + botão(ões). Pensado como referência
/// rápida durante o jogo, nunca parágrafo.
class GuideControlRow extends StatelessWidget {
  const GuideControlRow({
    required this.action,
    required this.playstation,
    required this.xbox,
    super.key,
  });

  final String action;
  final String playstation;
  final String xbox;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Text(action, style: context.textStyles.bodyMedium),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: Text(
              playstation,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: Text(
              xbox,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Cabeçalho fixo em português: o conteúdo destes guias (nomes de ações e
/// comandos reais de controle) ainda não foi traduzido -- ver nota no
/// handoff desta etapa.
class GuideControlHeaderRow extends StatelessWidget {
  const GuideControlHeaderRow({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Row(
      children: <Widget>[
        Expanded(
          flex: 3,
          child: Text(
            'Ação',
            style: context.textStyles.labelSmall?.copyWith(
              color: context.colors.textTertiary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 2,
          child: Text(
            'PlayStation',
            style: context.textStyles.labelSmall?.copyWith(
              color: context.colors.textTertiary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 2,
          child: Text(
            'Xbox / PC',
            style: context.textStyles.labelSmall?.copyWith(
              color: context.colors.textTertiary,
            ),
          ),
        ),
      ],
    ),
  );
}

class GuideBulletList extends StatelessWidget {
  const GuideBulletList(this.items, {super.key});

  final List<String> items;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('•  ', style: context.textStyles.bodyMedium),
                Expanded(
                  child: Text(
                    item,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
