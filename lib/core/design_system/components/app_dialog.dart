import 'package:fifa_queue/core/design_system/components/app_button.dart';
import 'package:fifa_queue/core/design_system/theme/theme_context_extensions.dart';
import 'package:fifa_queue/core/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) => showDialog<T>(
  context: context,
  barrierDismissible: barrierDismissible,
  builder: builder,
);

/// Confirmacao com duas acoes, resolvida em `true`/`false`. Atalho para o
/// caso mais comum, sem cada tela remontar o mesmo AppDialog.
Future<bool> showAppConfirm({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  bool isDestructive = false,
}) async =>
    await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        onCancel: () => Navigator.of(dialogContext).pop(false),
      ),
    ) ??
    false;

/// Aviso curto e nao bloqueante.
void showAppSnack(
  BuildContext context, {
  required String message,
  bool isError = false,
}) {
  final colors = context.colors;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colors.danger : colors.surfaceHighest,
      ),
    );
}

class AppDialog extends StatelessWidget {
  const AppDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
    this.cancelLabel,
    this.onCancel,
    this.isDestructive = false,
    super.key,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final String? cancelLabel;
  final VoidCallback? onCancel;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(title),
    content: Text(message, style: context.textStyles.bodyMedium),
    actionsPadding: const EdgeInsets.fromLTRB(
      AppSpacing.xl,
      0,
      AppSpacing.xl,
      AppSpacing.xl,
    ),
    actions: <Widget>[
      Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (isDestructive)
            AppButton.danger(label: confirmLabel, onPressed: onConfirm)
          else
            AppButton(label: confirmLabel, onPressed: onConfirm),
          if (cancelLabel != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            AppButton.ghost(
              label: cancelLabel!,
              expanded: true,
              onPressed: onCancel ?? () => Navigator.of(context).pop(),
            ),
          ],
        ],
      ),
    ],
  );
}
