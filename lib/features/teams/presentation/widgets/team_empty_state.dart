import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/create_team_sheet.dart';
import 'package:flutter/material.dart';

class TeamEmptyState extends StatelessWidget {
  const TeamEmptyState({super.key});

  Future<void> _openInviteInfo(BuildContext context) async {
    final l10n = context.l10n;
    await showAppBottomSheet<void>(
      context: context,
      builder: (sheetContext) => AppBottomSheet(
        title: l10n.teamInviteComingSoonTitle,
        actions: <Widget>[
          AppButton(
            label: l10n.teamCreateCta,
            icon: Icons.add,
            onPressed: () async {
              Navigator.of(sheetContext).pop();
              await showCreateTeamSheet(context);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.ghost(
            label: l10n.actionClose,
            expanded: true,
            onPressed: () => Navigator.of(sheetContext).pop(),
          ),
        ],
        child: Text(
          l10n.teamInviteComingSoonMessage,
          style: context.textStyles.bodyMedium,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.surfaceHighest,
                  borderRadius: AppRadii.borderLg,
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Icon(
                  Icons.groups_2_outlined,
                  size: AppSizing.iconXl,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.teamNoTeamTitle,
                textAlign: TextAlign.center,
                style: context.textStyles.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.teamNoTeamMessage,
                textAlign: TextAlign.center,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: l10n.teamCreateCta,
                icon: Icons.add,
                onPressed: () => showCreateTeamSheet(context),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton.ghost(
                label: l10n.teamHaveInviteCode,
                expanded: true,
                onPressed: () => _openInviteInfo(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
