import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/l10n/validation_l10n.dart';
import 'package:fifa_queue/core/validation/app_validators.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<bool> showCreateTeamSheet(BuildContext context) async {
  final cubit = context.read<TeamsCubit>();
  cubit.clearActionFailure();
  final created = await showAppBottomSheet<bool>(
    context: context,
    builder: (sheetContext) => BlocProvider<TeamsCubit>.value(
      value: cubit,
      child: const _CreateTeamForm(),
    ),
  );
  return created ?? false;
}

class _CreateTeamForm extends StatefulWidget {
  const _CreateTeamForm();

  @override
  State<_CreateTeamForm> createState() => _CreateTeamFormState();
}

class _CreateTeamFormState extends State<_CreateTeamForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onChanged);
    _tagController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_onChanged)
      ..dispose();
    _tagController
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() {
    context.read<TeamsCubit>().clearActionFailure();
    setState(() {});
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final navigator = Navigator.of(context);
    final team = await context.read<TeamsCubit>().createTeam(
      name: _nameController.text,
      tag: _tagController.text,
    );
    if (team != null && mounted) {
      navigator.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<TeamsCubit, TeamsState>(
      builder: (context, state) => AppBottomSheet(
        title: l10n.teamCreateTitle,
        subtitle: l10n.teamCreateSubtitle,
        actions: <Widget>[
          AppButton(
            label: l10n.teamCreateAction,
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
                label: l10n.teamNameLabel,
                hintText: l10n.teamNameHint,
                controller: _nameController,
                enabled: !state.isSaving,
                autofocus: true,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                maxLength: AppValidators.teamNameMaxLength,
                validator: (value) =>
                    AppValidators.teamName(value)?.message(l10n),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: l10n.teamTagLabel,
                hintText: l10n.teamTagHint,
                helperText: l10n.teamTagHelper,
                controller: _tagController,
                enabled: !state.isSaving,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.characters,
                maxLength: AppValidators.teamTagMaxLength,
                inputFormatters: <TextInputFormatter>[
                  UpperCaseTextFormatter(),
                  FilteringTextInputFormatter.allow(RegExp('[A-Z0-9]')),
                ],
                onSubmitted: (_) => _submit(),
                validator: (value) =>
                    AppValidators.teamTag(value)?.message(l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => TextEditingValue(
    text: newValue.text.toUpperCase(),
    selection: newValue.selection,
  );
}
