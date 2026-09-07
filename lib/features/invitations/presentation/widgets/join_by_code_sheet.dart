import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/invitations/domain/entities/pending_invite.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Future<void> showJoinByCodeSheet(BuildContext context) => showAppBottomSheet<void>(
  context: context,
  builder: (sheetContext) => const _JoinByCodeForm(),
);

class _JoinByCodeForm extends StatefulWidget {
  const _JoinByCodeForm();

  @override
  State<_JoinByCodeForm> createState() => _JoinByCodeFormState();
}

class _JoinByCodeFormState extends State<_JoinByCodeForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final code = InviteCode.normalize(_codeController.text);
    Navigator.of(context).pop();
    context.go(AppRoutes.joinTeamLocation(code));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppBottomSheet(
      title: l10n.teamHaveInviteCode,
      subtitle: l10n.inviteEnterCodeMessage,
      actions: <Widget>[
        AppButton(label: l10n.actionContinue, onPressed: _continue),
        const SizedBox(height: AppSpacing.sm),
        AppButton.ghost(
          label: l10n.actionClose,
          expanded: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: Form(
        key: _formKey,
        child: AppTextField(
          label: l10n.inviteCodeFieldLabel,
          hintText: 'A7K2PQ9XM4',
          controller: _codeController,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _continue(),
          validator: (value) => InviteCode.isValid(value ?? '')
              ? null
              : l10n.inviteCodeFieldInvalid,
        ),
      ),
    );
  }
}
