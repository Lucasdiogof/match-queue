import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Placar como contador manual: numero grande com "+" e "−" para ajustar,
/// um por coluna (vitorias/derrotas). Sem digitar nada -- um toque de cada vez.
class WinLossCounter extends StatelessWidget {
  const WinLossCounter({
    required this.wins,
    required this.losses,
    required this.winsLabel,
    required this.lossesLabel,
    required this.addWinTooltip,
    required this.addLossTooltip,
    required this.removeWinTooltip,
    required this.removeLossTooltip,
    this.onAddWin,
    this.onAddLoss,
    this.onRemoveWin,
    this.onRemoveLoss,
    super.key,
  });

  final int wins;
  final int losses;
  final String winsLabel;
  final String lossesLabel;
  final String addWinTooltip;
  final String addLossTooltip;
  final String removeWinTooltip;
  final String removeLossTooltip;
  final VoidCallback? onAddWin;
  final VoidCallback? onAddLoss;
  final VoidCallback? onRemoveWin;
  final VoidCallback? onRemoveLoss;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: _Column(
          value: wins,
          label: winsLabel,
          addTooltip: addWinTooltip,
          removeTooltip: removeWinTooltip,
          onAdd: onAddWin,
          onRemove: wins > 0 ? onRemoveWin : null,
        ),
      ),
      const SizedBox(width: AppSpacing.xl),
      Expanded(
        child: _Column(
          value: losses,
          label: lossesLabel,
          addTooltip: addLossTooltip,
          removeTooltip: removeLossTooltip,
          onAdd: onAddLoss,
          onRemove: losses > 0 ? onRemoveLoss : null,
        ),
      ),
    ],
  );
}

class _Column extends StatelessWidget {
  const _Column({
    required this.value,
    required this.label,
    required this.addTooltip,
    required this.removeTooltip,
    this.onAdd,
    this.onRemove,
  });

  final int value;
  final String label;
  final String addTooltip;
  final String removeTooltip;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

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
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AppIconButton(
            icon: Icons.remove,
            tooltip: removeTooltip,
            variant: AppIconButtonVariant.surface,
            onPressed: onRemove,
          ),
          const SizedBox(width: AppSpacing.sm),
          AppIconButton(
            icon: Icons.add,
            tooltip: addTooltip,
            variant: AppIconButtonVariant.surface,
            onPressed: onAdd,
          ),
        ],
      ),
    ],
  );
}
