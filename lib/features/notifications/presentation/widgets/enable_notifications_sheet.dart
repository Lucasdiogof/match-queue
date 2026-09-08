import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:flutter/material.dart';

/// Convite pré-permissão: explica o valor ANTES de o diálogo do sistema
/// aparecer (o do sistema só pode ser pedido uma vez). Retorna `true` se o
/// usuário topou — quem chamou é que dispara o `requestPermission` de fato.
Future<bool> showEnableNotificationsSheet(BuildContext context) async {
  final confirmed = await showAppBottomSheet<bool>(
    context: context,
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      return AppBottomSheet(
        title: l10n.notificationsEnableTitle,
        actions: <Widget>[
          AppButton(
            label: l10n.notificationsEnableCta,
            icon: Icons.notifications_active_outlined,
            onPressed: () => Navigator.of(sheetContext).pop(true),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.ghost(
            label: l10n.actionNotNow,
            expanded: true,
            onPressed: () => Navigator.of(sheetContext).pop(false),
          ),
        ],
        child: Text(
          l10n.notificationsEnableMessage,
          style: sheetContext.textStyles.bodyMedium,
        ),
      );
    },
  );
  return confirmed ?? false;
}
