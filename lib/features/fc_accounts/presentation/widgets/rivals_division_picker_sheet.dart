import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/rivals_division.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/rivals_division_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showRivalsDivisionPickerSheet({
  required BuildContext context,
  required String accountId,
  required RivalsDivision? selected,
}) async {
  final cubit = context.read<FcAccountsCubit>();
  await showAppBottomSheet<void>(
    context: context,
    builder: (sheetContext) => AppBottomSheet(
      title: context.l10n.fcAccountDivisionPickerTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _DivisionOptionRow(
            label: context.l10n.fcAccountDivisionNone,
            isSelected: selected == null,
            onTap: () {
              Navigator.of(sheetContext).pop();
              cubit.updateRivalsDivision(id: accountId, division: null);
            },
          ),
          for (final division in RivalsDivision.values)
            _DivisionOptionRow(
              label: division.label(context.l10n),
              isSelected: division == selected,
              onTap: () {
                Navigator.of(sheetContext).pop();
                cubit.updateRivalsDivision(id: accountId, division: division);
              },
            ),
        ],
      ),
    ),
  );
}

class _DivisionOptionRow extends StatelessWidget {
  const _DivisionOptionRow({
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
