import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_event.dart';
import 'package:flutter/material.dart';

/// A janela vem do banco (sexta -> segunda, fuso do Brasil) e chega em UTC;
/// exibir sempre em [toLocal] mantem a data igual a que o jogador viu no
/// jogo. O fim e exclusivo -- a semana termina na virada de domingo pra
/// segunda -- entao o rotulo mostra o domingo, nao a segunda.
String weekendLeagueRangeLabel(BuildContext context, WeekendLeagueEvent event) {
  final l10n = context.l10n;
  final start = event.startsAt.toLocal();
  final lastDay = event.endsAt.toLocal().subtract(const Duration(days: 1));
  return '${l10n.historyEntryDate(start)} – ${l10n.historyEntryDate(lastDay)}';
}

class WeekendLeagueWeekSelector extends StatelessWidget {
  const WeekendLeagueWeekSelector({
    required this.event,
    required this.onTap,
    super.key,
  });

  final WeekendLeagueEvent event;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Icon(
            Icons.calendar_month_outlined,
            size: AppSizing.iconLg,
            color: colors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.weekendLeagueBadge(event.number),
                  style: context.textStyles.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  weekendLeagueRangeLabel(context, event),
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            l10n.weekendLeagueChangeWeekAction,
            style: context.textStyles.labelMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          Icon(Icons.expand_more, color: colors.textTertiary),
        ],
      ),
    );
  }
}

Future<WeekendLeagueEvent?> showWeekendLeagueWeekPicker({
  required BuildContext context,
  required List<WeekendLeagueEvent> events,
  required String? selectedId,
}) => showAppBottomSheet<WeekendLeagueEvent>(
  context: context,
  builder: (sheetContext) => AppBottomSheet(
    title: sheetContext.l10n.weekendLeagueWeekPickerTitle,
    isChildScrollable: true,
    child: ListView.separated(
      shrinkWrap: true,
      itemCount: events.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (itemContext, index) {
        final event = events[index];
        return _WeekRow(
          event: event,
          isSelected: event.id == selectedId,
          onTap: () => Navigator.of(sheetContext).pop(event),
        );
      },
    ),
  ),
);

class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.event,
    required this.isSelected,
    required this.onTap,
  });

  final WeekendLeagueEvent event;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return AppCard(
      variant: isSelected ? AppCardVariant.elevated : AppCardVariant.outlined,
      onTap: onTap,
      borderColor: isSelected ? colors.borderStrong : null,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.weekendLeagueBadge(event.number),
                  style: context.textStyles.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  weekendLeagueRangeLabel(context, event),
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (event.isActive)
            AppBadge(
              label: l10n.weekendLeagueCurrentWeekBadge,
              tone: AppBadgeTone.success,
            )
          else if (isSelected)
            Icon(Icons.check_circle, color: colors.textPrimary),
        ],
      ),
    );
  }
}
