import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/l10n/validation_l10n.dart';
import 'package:fifa_queue/core/validation/app_validators.dart';
import 'package:fifa_queue/features/teams/domain/entities/team.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_state.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/create_team_sheet.dart'
    show UpperCaseTextFormatter;
import 'package:fifa_queue/features/teams/presentation/widgets/team_duration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<bool> showEditTeamSheet(BuildContext context, Team team) async {
  final cubit = context.read<TeamsCubit>();
  cubit.clearActionFailure();
  final saved = await showAppBottomSheet<bool>(
    context: context,
    builder: (sheetContext) => BlocProvider<TeamsCubit>.value(
      value: cubit,
      child: _EditTeamForm(team: team),
    ),
  );
  return saved ?? false;
}

class _EditTeamForm extends StatefulWidget {
  const _EditTeamForm({required this.team});

  final Team team;

  @override
  State<_EditTeamForm> createState() => _EditTeamFormState();
}

class _EditTeamFormState extends State<_EditTeamForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController = TextEditingController(
    text: widget.team.name,
  );
  late final TextEditingController _tagController = TextEditingController(
    text: widget.team.tag ?? '',
  );
  late int _durationSeconds = _closestOption(
    widget.team.defaultSearchDuration.inSeconds,
  );

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

  static int _closestOption(int seconds) {
    var best = TeamDurationOptions.values.first;
    for (final option in TeamDurationOptions.values) {
      if ((option - seconds).abs() < (best - seconds).abs()) {
        best = option;
      }
    }
    return best;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final navigator = Navigator.of(context);
    final normalizedTag = AppValidators.normalizeTeamTag(_tagController.text);
    final saved = await context.read<TeamsCubit>().updateTeam(
      teamId: widget.team.id,
      name: _nameController.text,
      tag: normalizedTag,
      clearTag: normalizedTag == null,
      defaultSearchDuration: Duration(seconds: _durationSeconds),
    );
    if (saved && mounted) {
      navigator.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<TeamsCubit, TeamsState>(
      builder: (context, state) => AppBottomSheet(
        title: l10n.teamEditTitle,
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
                validator: (value) =>
                    AppValidators.teamTag(value)?.message(l10n),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.teamSearchDurationLabel.toUpperCase(),
                style: context.textStyles.labelSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.teamSearchDurationHelper,
                style: context.textStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  for (final option in TeamDurationOptions.values)
                    AppChip(
                      label: teamDurationLabel(l10n, option),
                      isSelected: _durationSeconds == option,
                      onPressed: state.isSaving
                          ? null
                          : () => setState(() => _durationSeconds = option),
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
