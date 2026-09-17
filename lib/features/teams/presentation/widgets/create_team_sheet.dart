import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/l10n/validation_l10n.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/core/validation/app_validators.dart';
import 'package:fifa_queue/features/account/presentation/cubit/account_cubit.dart';
import 'package:fifa_queue/features/teams/domain/entities/team.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_state.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_logo_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Retorna o time criado (ou null se cancelado) e ja empurra pra dentro
/// dele -- criar um time e ficar olhando pra lista de volta nao faz
/// sentido, o dono quer estar dentro pra convidar gente/configurar.
Future<Team?> showCreateTeamSheet(BuildContext context) async {
  final teamsCubit = context.read<TeamsCubit>();
  final accountCubit = context.read<AccountCubit>();
  teamsCubit.clearActionFailure();
  final team = await showAppBottomSheet<Team>(
    context: context,
    builder: (sheetContext) => MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<TeamsCubit>.value(value: teamsCubit),
        BlocProvider<AccountCubit>.value(value: accountCubit),
      ],
      child: const _TeamDetailsForm(),
    ),
  );
  if (team != null && context.mounted) {
    await context.push(AppRoutes.teamDetailLocation(team.id));
  }
  return team;
}

/// Nome, tag e logo -- o dono e sempre a conta autenticada, entao nao ha
/// nada a escolher sobre "quem" cria o time.
class _TeamDetailsForm extends StatefulWidget {
  const _TeamDetailsForm();

  @override
  State<_TeamDetailsForm> createState() => _TeamDetailsFormState();
}

class _TeamDetailsFormState extends State<_TeamDetailsForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  PickedTeamLogo? _pickedLogo;

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
    final l10n = context.l10n;
    final teamsCubit = context.read<TeamsCubit>();
    final displayName = context.read<AccountCubit>().state.displayName;
    final normalizedName = AppValidators.normalizeTeamName(
      _nameController.text,
    );
    // Nome e opcional: quem nao quiser digitar recebe um default derivado do
    // proprio nome da conta, em vez de ser travado no formulario.
    final name = normalizedName.isEmpty
        ? l10n.teamDefaultName(displayName)
        : normalizedName;
    final team = await teamsCubit.createTeam(
      name: name,
      tag: _tagController.text,
    );
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
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  maxLength: AppValidators.teamNameMaxLength,
                  // Opcional: em branco, _submit gera um default a partir do
                  // nome da conta. So valida tamanho quando algo foi digitado.
                  validator: (value) {
                    if (AppValidators.normalizeTeamName(value ?? '').isEmpty) {
                      return null;
                    }
                    return AppValidators.teamName(value)?.message(l10n);
                  },
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
