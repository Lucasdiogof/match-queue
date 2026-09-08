import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_squad.dart';
import 'package:fifa_queue/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Explica o 0-3 de um titular. Os números vêm do backend; aqui só se
/// escolhe como dizê-los.
Future<void> showPlayerChemistrySheet({
  required BuildContext context,
  required SquadSlot slot,
  String? ruleVersion,
}) {
  final sources = slot.chemistrySources;
  return showAppBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      return AppBottomSheet(
        title: slot.card.displayName,
        subtitle: l10n.squadChemistryPlayerTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _ChemistryTotal(value: slot.chemistry ?? 0, max: 3),
            const SizedBox(height: AppSpacing.lg),
            if (sources == null || !sources.eligible)
              AppBanner(
                tone: AppBannerTone.warning,
                message: l10n.squadChemistryOutOfPositionExplain,
              )
            else ...<Widget>[
              if (sources.club +
                      sources.league +
                      sources.nation +
                      sources.manager ==
                  0)
                Text(
                  l10n.squadChemistryNoSources,
                  style: sheetContext.textStyles.bodySmall?.copyWith(
                    color: sheetContext.colors.textSecondary,
                  ),
                )
              else ...<Widget>[
                _SourceRow(
                  label: l10n.squadChemistrySourceClub,
                  points: sources.club,
                  shared: sources.clubCount,
                ),
                _SourceRow(
                  label: l10n.squadChemistrySourceLeague,
                  points: sources.league,
                  shared: sources.leagueCount,
                ),
                _SourceRow(
                  label: l10n.squadChemistrySourceNation,
                  points: sources.nation,
                  shared: sources.nationCount,
                ),
                _SourceRow(
                  label: l10n.squadChemistrySourceManager,
                  points: sources.manager,
                ),
              ],
              if (sources.capped) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.squadChemistryCappedNote,
                  style: sheetContext.textStyles.bodySmall?.copyWith(
                    color: sheetContext.colors.textTertiary,
                  ),
                ),
              ],
            ],
            if (ruleVersion != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.squadChemistryRuleNote(ruleVersion),
                style: sheetContext.textStyles.bodySmall?.copyWith(
                  color: sheetContext.colors.textTertiary,
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

/// Visão do squad inteiro: total, quem está cheio, quem está zerado e o que
/// está atrapalhando. As "sugestões" são leitura direta do estado, não um
/// recomendador (item 47).
Future<void> showSquadChemistrySheet({
  required BuildContext context,
  required FcSquadDetail squad,
}) {
  final starters = squad.slots
      .where((s) => s.type == SquadSlotType.starting)
      .toList();
  final full = starters.where((s) => (s.chemistry ?? 0) >= 3).length;
  final zero = starters.where((s) => (s.chemistry ?? 0) == 0).length;
  final outOfPosition = starters.where((s) => !s.positionEligible).length;
  final empty = squad.formation.slots.length - starters.length;
  final maxChemistry = squad.formation.slots.length * 3;

  return showAppBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      return AppBottomSheet(
        title: l10n.squadChemistryDetailTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _ChemistryTotal(value: squad.chemistry, max: maxChemistry),
            const SizedBox(height: AppSpacing.lg),
            _Insight(text: l10n.squadChemistryFullPlayers(full)),
            if (zero > 0) _Insight(text: l10n.squadChemistryLowPlayers(zero)),
            if (outOfPosition > 0)
              _Insight(
                text: l10n.squadChemistryOutOfPositionCount(outOfPosition),
                tone: AppBannerTone.warning,
              ),
            if (empty > 0)
              _Insight(text: l10n.squadChemistryEmptySlotsNote(empty)),
            if (starters.isNotEmpty) ...<Widget>[
              const AppDivider(spacing: AppSpacing.lg),
              for (final slot in starters) _PlayerLine(slot: slot, l10n: l10n),
            ],
            if (squad.chemistryRuleVersion != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.squadChemistryRuleNote(squad.chemistryRuleVersion!),
                style: sheetContext.textStyles.bodySmall?.copyWith(
                  color: sheetContext.colors.textTertiary,
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _ChemistryTotal extends StatelessWidget {
  const _ChemistryTotal({required this.value, required this.max});

  final int value;
  final int max;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ratio = max == 0 ? 0.0 : value / max;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('$value/$max', style: context.textStyles.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: AppRadii.borderPill,
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: colors.surfaceHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              ratio >= 0.75
                  ? colors.success
                  : ratio >= 0.4
                  ? colors.warning
                  : colors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.label, required this.points, this.shared});

  final String label;
  final int points;
  final int? shared;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final count = shared;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: context.textStyles.bodyMedium?.copyWith(
                color: points > 0 ? colors.textPrimary : colors.textTertiary,
              ),
            ),
          ),
          if (count != null && count > 1) ...<Widget>[
            Text(
              '$count',
              style: context.textStyles.bodySmall?.copyWith(
                color: colors.textTertiary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            points > 0 ? '+$points' : '0',
            style: context.textStyles.bodyMedium?.copyWith(
              color: points > 0 ? colors.success : colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Insight extends StatelessWidget {
  const _Insight({required this.text, this.tone = AppBannerTone.neutral});

  final String text;
  final AppBannerTone tone;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: AppBanner(tone: tone, message: text),
  );
}

class _PlayerLine extends StatelessWidget {
  const _PlayerLine({required this.slot, required this.l10n});

  final SquadSlot slot;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final chemistry = slot.chemistry ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 44,
            child: Text(
              slot.slotCode,
              style: context.textStyles.bodySmall?.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              slot.card.displayName,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.bodyMedium,
            ),
          ),
          if (!slot.positionEligible) ...<Widget>[
            AppBadge(
              label: l10n.squadPositionBadgeOutOfPosition,
              tone: AppBadgeTone.warning,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            '$chemistry',
            style: context.textStyles.bodyMedium?.copyWith(
              color: chemistry >= 3
                  ? colors.success
                  : chemistry == 0
                  ? colors.textTertiary
                  : colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
