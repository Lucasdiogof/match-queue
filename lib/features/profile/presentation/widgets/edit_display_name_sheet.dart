import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/l10n/validation_l10n.dart';
import 'package:fifa_queue/core/validation/app_validators.dart';
import 'package:fifa_queue/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:fifa_queue/features/profile/presentation/cubit/profile_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<bool> showEditDisplayNameSheet({
  required BuildContext context,
  required String currentDisplayName,
}) async {
  final cubit = context.read<ProfileCubit>();
  final saved = await showAppBottomSheet<bool>(
    context: context,
    builder: (sheetContext) => BlocProvider<ProfileCubit>.value(
      value: cubit,
      child: _EditDisplayNameForm(initialValue: currentDisplayName),
    ),
  );
  return saved ?? false;
}

class _EditDisplayNameForm extends StatefulWidget {
  const _EditDisplayNameForm({required this.initialValue});

  final String initialValue;

  @override
  State<_EditDisplayNameForm> createState() => _EditDisplayNameFormState();
}

class _EditDisplayNameFormState extends State<_EditDisplayNameForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() {
    context.read<ProfileCubit>().clearFailure();
    setState(() {});
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final navigator = Navigator.of(context);
    final saved = await context.read<ProfileCubit>().updateDisplayName(
      _controller.text,
    );
    if (saved && mounted) {
      navigator.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final length = AppValidators.normalizeDisplayName(
      _controller.text,
    ).runes.length;

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) => AppBottomSheet(
        title: l10n.profileEditNameTitle,
        actions: <Widget>[
          AppButton(
            label: l10n.actionSave,
            isLoading: state.isSaving,
            onPressed: state.isSaving ? null : _save,
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
              if (state.failure != null) ...<Widget>[
                AppBanner(
                  tone: AppBannerTone.danger,
                  message: state.failure!.localizedMessage(l10n),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              AppTextField(
                label: l10n.profileDisplayNameLabel,
                hintText: l10n.authDisplayNameHint,
                controller: _controller,
                enabled: !state.isSaving,
                autofocus: true,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.words,
                maxLength: AppValidators.displayNameMaxLength,
                onSubmitted: (_) => _save(),
                validator: (value) =>
                    AppValidators.displayName(value)?.message(l10n),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  l10n.profileDisplayNameCounter(
                    length,
                    AppValidators.displayNameMaxLength,
                  ),
                  style: context.textStyles.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
