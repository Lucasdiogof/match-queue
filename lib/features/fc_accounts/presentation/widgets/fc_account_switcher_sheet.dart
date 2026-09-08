import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/create_fc_account_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showFcAccountSwitcherSheet({
  required BuildContext context,
  required List<FcAccount> accounts,
  required String? selectedAccountId,
}) async {
  final cubit = context.read<FcAccountsCubit>();
  await showAppBottomSheet<void>(
    context: context,
    builder: (sheetContext) => BlocProvider<FcAccountsCubit>.value(
      value: cubit,
      child: AppBottomSheet(
        title: context.l10n.fcAccountSwitchTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final account in accounts)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _FcAccountRow(
                  account: account,
                  isSelected: account.id == selectedAccountId,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    cubit.selectAccount(account.id);
                  },
                ),
              ),
            AppButton.ghost(
              label: context.l10n.fcAccountSwitchCreateAction,
              icon: Icons.add,
              expanded: true,
              onPressed: () async {
                Navigator.of(sheetContext).pop();
                if (context.mounted) {
                  await showCreateFcAccountSheet(context);
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _FcAccountRow extends StatelessWidget {
  const _FcAccountRow({
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
