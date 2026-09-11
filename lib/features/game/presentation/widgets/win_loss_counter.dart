import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Placar como contador manual: numero grande + um "+" logo abaixo, um por
/// coluna (vitorias/derrotas). Sem digitar nada -- um toque de cada vez,
/// pensado pra registrar 15-0 aos poucos durante a campanha.
class WinLossCounter extends StatelessWidget {
  const WinLossCounter({
    required this.wins,
    required this.losses,
    required this.winsLabel,
    required this.lossesLabel,
    required this.addWinTooltip,
    required this.addLossTooltip,
    this.onAddWin,
    this.onAddLoss,
    super.key,
  });

  final int wins;
  final int losses;
  final String winsLabel;
  final String lossesLabel;
  final String addWinTooltip;
  final String addLossTooltip;
  final VoidCallback? onAddWin;
  final VoidCallback? onAddLoss;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: _Column(
          value: wins,
          label: winsLabel,
          tooltip: addWinTooltip,
          onAdd: onAddWin,
        ),
      ),
      const SizedBox(width: AppSpacing.xl),
      Expanded(
        child: _Column(
          value: losses,
          label: lossesLabel,
          tooltip: addLossTooltip,
          onAdd: onAddLoss,
        ),
      ),
    ],
  );
}

class _Column extends StatelessWidget {
  const _Column({
    required this.value,
    required this.label,
    required this.tooltip,
    this.onAdd,
  });

  final int value;
  final String label;
  final String tooltip;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      Text('$value', style: context.textStyles.headlineMedium),
      const SizedBox(height: AppSpacing.xxs),
      Text(
        label,
        style: context.textStyles.labelSmall?.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      AppIconButton(
        icon: Icons.add,
        tooltip: tooltip,
        variant: AppIconButtonVariant.surface,
        onPressed: onAdd,
      ),
    ],
  );
}
