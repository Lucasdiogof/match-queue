import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/l10n/validation_l10n.dart';
import 'package:fifa_queue/core/validation/app_validators.dart';
import 'package:fifa_queue/features/profiles/domain/entities/profile_platform.dart';
import 'package:fifa_queue/features/profiles/presentation/cubit/profiles_cubit.dart';
import 'package:fifa_queue/features/profiles/presentation/cubit/profiles_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<bool> showCreateProfileSheet(BuildContext context) async {
  final cubit = context.read<ProfilesCubit>();
  cubit.clearActionFailure();
  final created = await showAppBottomSheet<bool>(
    context: context,
    builder: (sheetContext) => BlocProvider<ProfilesCubit>.value(
      value: cubit,
      child: const _CreateProfileForm(),
    ),
  );
  return created ?? false;
}

class _CreateProfileForm extends StatefulWidget {
  const _CreateProfileForm();

  @override
  State<_CreateProfileForm> createState() => _CreateProfileFormState();
}

class _CreateProfileFormState extends State<_CreateProfileForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  ProfilePlatform? _platform;

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
    final ok = await context.read<ProfilesCubit>().createProfile(
      _nameController.text,
      platform: _platform,
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
        title: l10n.profileCreateTitle,
        subtitle: l10n.profileCreateSubtitle,
        actions: <Widget>[
          AppButton(
            label: l10n.profileCreateAction,
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
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.profilePlatformLabel,
                style: context.textStyles.labelMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: <Widget>[
                  for (final platform in ProfilePlatform.values)
                    AppChip(
                      label: platform.displayLabel,
                      isSelected: _platform == platform,
                      onPressed: state.isSaving
                          ? null
                          : () => setState(
                              () => _platform = _platform == platform
                                  ? null
                                  : platform,
                            ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
