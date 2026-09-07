import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_membership.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_avatar.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_role_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showTeamSelectorSheet({
  required BuildContext context,
  required List<UserTeam> teams,
  required String? selectedTeamId,
}) async {
  final cubit = context.read<TeamsCubit>();
  await showAppBottomSheet<void>(
    context: context,
    builder: (sheetContext) => AppBottomSheet(
      title: context.l10n.teamSwitchTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final userTeam in teams)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _TeamRow(
                userTeam: userTeam,
                isSelected: userTeam.id == selectedTeamId,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  cubit.selectTeam(userTeam.id);
                },
              ),
            ),
        ],
      ),
    ),
  );
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({
    required this.userTeam,
    required this.isSelected,
    required this.onTap,
  });

  final UserTeam userTeam;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final team = userTeam.team;

    return AppCard(
      variant: isSelected ? AppCardVariant.elevated : AppCardVariant.outlined,
      onTap: onTap,
      borderColor: isSelected ? colors.borderStrong : null,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: <Widget>[
          TeamAvatar(team: team, size: AppSizing.avatarMd),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(team.name, style: context.textStyles.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  userTeam.role.label(context.l10n),
                  style: context.textStyles.bodySmall,
                ),
              ],
            ),
          ),
          if (isSelected)
            Icon(Icons.check_circle, color: colors.textPrimary)
          else
            Icon(Icons.chevron_right, color: colors.textTertiary),
        ],
      ),
    );
  }
}
