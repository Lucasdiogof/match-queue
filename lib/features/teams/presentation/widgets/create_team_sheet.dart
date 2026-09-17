import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/l10n/validation_l10n.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/core/validation/app_validators.dart';
import 'package:fifa_queue/features/teams/domain/entities/team.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_state.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_logo_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Retorna o time criado (ou null se cancelado) e ja empurra pra dentro
/// dele -- criar um time e ficar olhando pra lista de volta nao faz
/// sentido, o dono quer estar dentro pra convidar gente/configurar.
Future<Team?> showCreateTeamSheet(BuildContext context) async {
  final teamsCubit = context.read<TeamsCubit>();
  teamsCubit.clearActionFailure();
  final team = await showAppBottomSheet<Team>(
    context: context,
    builder: (sheetContext) => BlocProvider<TeamsCubit>.value(
      value: teamsCubit,
      child: const _TeamDetailsForm(),
    ),
  );
  if (team != null && context.mounted) {
    await context.push(AppRoutes.teamDetailLocation(team.id));
  }
  return team;
}

/// Nome e logo -- o dono e sempre a conta autenticada, entao nao ha nada a
/// escolher sobre "quem" cria o time. Sem tag: era um campo opcional que
/// ninguem pedia pra ver, e decisao do dono do produto foi tirar de toda
/// tela em vez de manter mais um campo que nao se usa.
class _TeamDetailsForm extends StatefulWidget {
  const _TeamDetailsForm();

  @override
  State<_TeamDetailsForm> createState() => _TeamDetailsFormState();
}

class _TeamDetailsFormState extends State<_TeamDetailsForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  PickedTeamLogo? _pickedLogo;

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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final navigator = Navigator.of(context);
    final teamsCubit = context.read<TeamsCubit>();
    final name = AppValidators.normalizeTeamName(_nameController.text);
    final team = await teamsCubit.createTeam(name: name);
    if (team == null) {
      return;
    }
    final logo = _pickedLogo;
    if (logo != null) {
      // Best-effort: o time ja existe nesse ponto: uma falha aqui nunca
      // desfaz a criacao, so deixa sem logo pra tentar de novo depois na
      // edicao do time.
      await teamsCubit.uploadAndSetTeamLogo(
        teamId: team.id,
        bytes: logo.bytes,
        contentType: logo.contentType,
      );
    }
    if (mounted) {
      navigator.pop(team);
    }
  }

  Future<void> _pickLogo() async {
    final picked = await pickTeamLogoBytes();
    if (picked != null && mounted) {
      setState(() => _pickedLogo = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<TeamsCubit, TeamsState>(
      builder: (context, state) => AppBottomSheet(
        title: l10n.teamCreateTitle,
        subtitle: l10n.teamCreateSubtitle,
        isChildScrollable: true,
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
                : () => Navigator.of(context).pop(),
          ),
        ],
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Center(
                  child: Column(
                    children: <Widget>[
                      _LogoPreview(logo: _pickedLogo),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton.ghost(
                        label: l10n.teamLogoAddAction,
                        icon: Icons.photo_camera_outlined,
                        onPressed: state.isSaving ? null : _pickLogo,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
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
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.words,
                  maxLength: AppValidators.teamNameMaxLength,
                  validator: (value) =>
                      AppValidators.teamName(value)?.message(l10n),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoPreview extends StatelessWidget {
  const _LogoPreview({required this.logo});

  final PickedTeamLogo? logo;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final picked = logo;

    return SizedBox(
      width: AppSizing.avatarXl,
      height: AppSizing.avatarXl,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceHighest,
          borderRadius: BorderRadius.circular(AppSizing.avatarXl * 0.28),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: picked == null
            ? Icon(
                Icons.groups_outlined,
                color: colors.textTertiary,
                size: AppSizing.avatarXl * 0.5,
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(AppSizing.avatarXl * 0.28),
                child: Image.memory(picked.bytes, fit: BoxFit.cover),
              ),
      ),
    );
  }
}
