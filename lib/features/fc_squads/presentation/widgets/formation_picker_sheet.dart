import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/formation.dart';
import 'package:flutter/material.dart';

Future<String?> showFormationPickerSheet({
  required BuildContext context,
  required List<FormationDefinition> formations,
  required String? selectedCode,
}) => showAppBottomSheet<String>(
  context: context,
  builder: (sheetContext) => AppBottomSheet(
    title: sheetContext.l10n.squadFormationPickerTitle,
    child: SizedBox(
      height: MediaQuery.sizeOf(sheetContext).height * 0.5,
      child: ListView.builder(
        itemCount: formations.length,
        itemBuilder: (context, index) {
          final formation = formations[index];
          return _FormationTile(
            formation: formation,
            isSelected: formation.code == selectedCode,
            onTap: () => Navigator.of(context).pop(formation.code),
          );
        },
      ),
    ),
  ),
);

class _FormationTile extends StatelessWidget {
  const _FormationTile({
    required this.formation,
    required this.isSelected,
    required this.onTap,
  });

  final FormationDefinition formation;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: onTap,
        borderColor: isSelected ? colors.textPrimary : null,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: <Widget>[
            // Miniatura das posições: mostra a forma da formação sem custar
            // uma tela de preview separada.
            _FormationThumbnail(slots: formation.slots),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                formation.displayName,
                style: context.textStyles.bodyLarge,
              ),
            ),
            if (isSelected)
              Icon(Icons.check, size: 18, color: colors.textPrimary),
          ],
        ),
      ),
    );
  }
}

class _FormationThumbnail extends StatelessWidget {
  const _FormationThumbnail({required this.slots});

  final List<FormationSlot> slots;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const width = 34.0;
    const height = 44.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: AppRadii.borderXs,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Stack(
        children: <Widget>[
          for (final slot in slots)
            Positioned(
              left: slot.x * (width - 6) - 1,
              top: (1 - slot.y) * (height - 6) - 1,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
