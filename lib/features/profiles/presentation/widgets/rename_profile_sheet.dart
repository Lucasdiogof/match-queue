import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/l10n/validation_l10n.dart';
import 'package:fifa_queue/core/validation/app_validators.dart';
import 'package:fifa_queue/features/profiles/presentation/cubit/profiles_cubit.dart';
import 'package:fifa_queue/features/profiles/presentation/cubit/profiles_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<bool> showRenameProfileSheet({
  required BuildContext context,
  required String profileId,
  required String currentName,
}) async {
  final cubit = context.read<ProfilesCubit>();
  cubit.clearActionFailure();
  final renamed = await showAppBottomSheet<bool>(
    context: context,
    builder: (sheetContext) => BlocProvider<ProfilesCubit>.value(
      value: cubit,
      child: _RenameProfileForm(
        profileId: profileId,
        initialValue: currentName,
      ),
    ),
  );
  return renamed ?? false;
}

class _RenameProfileForm extends StatefulWidget {
  const _RenameProfileForm({
    required this.profileId,
    required this.initialValue,
  });

  final String profileId;
  final String initialValue;

  @override
  State<_RenameProfileForm> createState() => _RenameProfileFormState();
}

class _RenameProfileFormState extends State<_RenameProfileForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController = TextEditingController(
    text: widget.initialValue,
  );

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
    context.read<ProfilesCubit>().clearActionFailure();
    setState(() {});
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final navigator = Navigator.of(context);
    final ok = await context.read<ProfilesCubit>().updateProfile(
      id: widget.profileId,
      name: _nameController.text,
    );
    if (ok && mounted) {
      navigator.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<ProfilesCubit, ProfilesState>(
      builder: (context, state) => AppBottomSheet(
        title: l10n.profileRenameTitle,
        actions: <Widget>[
          AppButton(
            label: l10n.profileRenameAction,
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
                label: l10n.profileNameLabel,
                hintText: l10n.profileNameHint,
                controller: _nameController,
                enabled: !state.isSaving,
                autofocus: true,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.words,
                maxLength: AppValidators.profileNameMaxLength,
                onSubmitted: (_) => _submit(),
                validator: (value) =>
                    AppValidators.profileName(value)?.message(l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
