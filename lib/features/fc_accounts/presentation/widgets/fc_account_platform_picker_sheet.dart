import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account_platform.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Mesmo padrao de showRivalsDivisionPickerSheet -- so 3 opcoes fixas aqui
/// (PC/PS/XBOX), nao precisa de isChildScrollable.
Future<void> showFcAccountPlatformPickerSheet({
  required BuildContext context,
  required String accountId,
  required FcAccountPlatform? selected,
}) async {
  final cubit = context.read<FcAccountsCubit>();
  await showAppBottomSheet<void>(
    context: context,
    builder: (sheetContext) => AppBottomSheet(
      title: context.l10n.fcAccountPlatformPickerTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _PlatformOptionRow(
            label: context.l10n.fcAccountPlatformNone,
            isSelected: selected == null,
            onTap: () {
              Navigator.of(sheetContext).pop();
              cubit.updatePlatform(id: accountId, platform: null);
            },
          ),
          for (final platform in FcAccountPlatform.values)
            _PlatformOptionRow(
              label: platform.displayLabel,
              isSelected: platform == selected,
              onTap: () {
                Navigator.of(sheetContext).pop();
                cubit.updatePlatform(id: accountId, platform: platform);
              },
            ),
        ],
      ),
    ),
  );
}

class _PlatformOptionRow extends StatelessWidget {
  const _PlatformOptionRow({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(label, style: context.textStyles.bodyLarge)),
            if (isSelected) Icon(Icons.check, color: colors.textPrimary),
          ],
        ),
      ),
    );
  }
}
