import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account.dart';
import 'package:fifa_queue/features/public_profile/presentation/cubit/sharing_settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showPublicAccountPickerSheet({
  required BuildContext context,
  required List<FcAccount> accounts,
  required String? selectedAccountId,
}) async {
  final cubit = context.read<SharingSettingsCubit>();
  await showAppBottomSheet<void>(
    context: context,
    builder: (sheetContext) => AppBottomSheet(
      title: context.l10n.publicProfileAccountLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final account in accounts.where((a) => a.isActive))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _AccountRow(
                account: account,
                isSelected: account.id == selectedAccountId,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  cubit.setFcAccountId(account.id);
                },
              ),
            ),
        ],
      ),
    ),
  );
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.isSelected,
    required this.onTap,
  });

  final FcAccount account;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppCard(
      variant: isSelected ? AppCardVariant.elevated : AppCardVariant.outlined,
      onTap: onTap,
      borderColor: isSelected ? colors.borderStrong : null,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.sports_esports_outlined,
            color: colors.textSecondary,
            size: AppSizing.iconMd,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(account.name, style: context.textStyles.titleSmall),
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
