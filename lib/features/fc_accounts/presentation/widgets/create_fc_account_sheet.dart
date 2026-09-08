import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/l10n/validation_l10n.dart';
import 'package:fifa_queue/core/validation/app_validators.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<bool> showCreateFcAccountSheet(BuildContext context) async {
  final cubit = context.read<FcAccountsCubit>();
  cubit.clearActionFailure();
  final created = await showAppBottomSheet<bool>(
    context: context,
    builder: (sheetContext) => BlocProvider<FcAccountsCubit>.value(
      value: cubit,
      child: const _CreateFcAccountForm(),
    ),
  );
  return created ?? false;
}

class _CreateFcAccountForm extends StatefulWidget {
  const _CreateFcAccountForm();

  @override
  State<_CreateFcAccountForm> createState() => _CreateFcAccountFormState();
}

class _CreateFcAccountFormState extends State<_CreateFcAccountForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() {
    context.read<FcAccountsCubit>().clearActionFailure();
    setState(() {});
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final navigator = Navigator.of(context);
    final ok = await context.read<FcAccountsCubit>().createAccount(
      _nameController.text,
    );
    if (ok && mounted) {
      navigator.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<FcAccountsCubit, FcAccountsState>(
      builder: (context, state) => AppBottomSheet(
        title: l10n.fcAccountCreateTitle,
        subtitle: l10n.fcAccountCreateSubtitle,
        actions: <Widget>[
          AppButton(
            label: l10n.fcAccountCreateAction,
            icon: Icons.add,
            isLoading: state.isSaving,
            onPressed: state.isSaving ? null : _submit,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.ghost(
            label: l10n.actionCancel,
            expanded: true,
            onPressed: state.isSaving
                ? null
                : () => Navigator.of(context).pop(false),
          ),
        ],
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (state.actionFailure != null) ...<Widget>[
                AppBanner(
                  tone: AppBannerTone.danger,
                  message: state.actionFailure!.localizedMessage(l10n),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              AppTextField(
                label: l10n.fcAccountNameLabel,
                hintText: l10n.fcAccountNameHint,
                controller: _nameController,
                enabled: !state.isSaving,
                autofocus: true,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.words,
                maxLength: AppValidators.fcAccountNameMaxLength,
                onSubmitted: (_) => _submit(),
                validator: (value) =>
                    AppValidators.fcAccountName(value)?.message(l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
