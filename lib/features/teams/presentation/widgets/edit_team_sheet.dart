import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/l10n/validation_l10n.dart';
import 'package:fifa_queue/core/validation/app_validators.dart';
import 'package:fifa_queue/features/teams/domain/entities/team.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_state.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_avatar.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_logo_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<bool> showEditTeamSheet(
  BuildContext context,
  Team team, {
  required bool isOwner,
}) async {
  final cubit = context.read<TeamsCubit>();
  cubit.clearActionFailure();
  final saved = await showAppBottomSheet<bool>(
    context: context,
    builder: (sheetContext) => BlocProvider<TeamsCubit>.value(
      value: cubit,
      child: _EditTeamForm(team: team, isOwner: isOwner),
    ),
  );
  return saved ?? false;
}

class _EditTeamForm extends StatefulWidget {
  const _EditTeamForm({required this.team, required this.isOwner});

  final Team team;
  final bool isOwner;

  @override
  State<_EditTeamForm> createState() => _EditTeamFormState();
}

class _EditTeamFormState extends State<_EditTeamForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController = TextEditingController(
    text: widget.team.name,
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
    context.read<TeamsCubit>().clearActionFailure();
    setState(() {});
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final navigator = Navigator.of(context);
    final saved = await context.read<TeamsCubit>().updateTeam(
      teamId: widget.team.id,
      name: _nameController.text,
    );
    if (saved && mounted) {
      navigator.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<TeamsCubit, TeamsState>(
      builder: (context, state) {
        // Time ao vivo do cubit, nao o snapshot capturado quando o sheet
        // abriu -- senao trocar/remover a logo na mesma sessao do sheet
        // deixaria o botao "Remover logo" com o estado antigo.
        var team = widget.team;
        for (final userTeam in state.teams) {
          if (userTeam.id == widget.team.id) {
            team = userTeam.team;
            break;
          }
        }

        return AppBottomSheet(
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
                if (widget.isOwner) ...<Widget>[
                  Center(
                    child: TeamLogoPicker(
                      teamId: team.id,
                      isSaving: state.isSaving,
                      hasLogo: team.logoUrl != null,
                      preview: TeamAvatar(team: team, size: AppSizing.avatarXl),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
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
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.words,
                  maxLength: AppValidators.teamNameMaxLength,
                  validator: (value) =>
                      AppValidators.teamName(value)?.message(l10n),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
