import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/l10n/validation_l10n.dart';
import 'package:fifa_queue/core/validation/app_validators.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_state.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/create_fc_account_sheet.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<bool> showCreateTeamSheet(BuildContext context) async {
  final teamsCubit = context.read<TeamsCubit>();
  final fcAccountsCubit = context.read<FcAccountsCubit>();
  teamsCubit.clearActionFailure();
  final created = await showAppBottomSheet<bool>(
    context: context,
    builder: (sheetContext) => MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<TeamsCubit>.value(value: teamsCubit),
        BlocProvider<FcAccountsCubit>.value(value: fcAccountsCubit),
      ],
      child: const _CreateTeamForm(),
    ),
  );
  return created ?? false;
}

/// Time exige pelo menos uma Conta FC do dono (gameplay flows refresh,
/// item 1): sem nenhuma, o sheet mostra o convite pra criar a primeira em
/// vez do formulário -- nunca deixa criar um time "órfão" de Conta FC.
class _CreateTeamForm extends StatelessWidget {
  const _CreateTeamForm();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<FcAccountsCubit, FcAccountsState>(
        buildWhen: (previous, current) =>
            previous.accounts != current.accounts ||
            previous.status != current.status,
        builder: (context, fcState) {
          if (fcState.status == FcAccountsStatus.loading &&
              !fcState.hasAccounts) {
            return const AppBottomSheet(
              child: SizedBox(height: 96, child: AppLoading.inline()),
            );
          }
          if (!fcState.hasAccounts) {
            return const _NeedsFcAccountBody();
          }
          return _TeamDetailsForm(accounts: fcState.accounts);
        },
      );
}

class _NeedsFcAccountBody extends StatelessWidget {
  const _NeedsFcAccountBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppBottomSheet(
      title: l10n.fcAccountOnboardingTitle,
      subtitle: l10n.fcAccountOnboardingMessage,
      actions: <Widget>[
        AppButton(
          label: l10n.fcAccountOnboardingCreateAction,
          icon: Icons.add,
          onPressed: () => showCreateFcAccountSheet(context),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton.ghost(
          label: l10n.actionClose,
          expanded: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
      child: const SizedBox.shrink(),
    );
  }
}

class _TeamDetailsForm extends StatefulWidget {
  const _TeamDetailsForm({required this.accounts});

  final List<FcAccount> accounts;

  @override
  State<_TeamDetailsForm> createState() => _TeamDetailsFormState();
}

class _TeamDetailsFormState extends State<_TeamDetailsForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  late Set<String> _selectedAccountIds;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onChanged);
    _tagController.addListener(_onChanged);
    // Uma única conta: pré-selecionada (item 15). Várias: começa vazio,
    // usuário escolhe explicitamente quais entram no time.
    _selectedAccountIds = widget.accounts.length == 1
        ? <String>{widget.accounts.first.id}
        : <String>{};
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
    if (_selectedAccountIds.isEmpty) {
      return;
    }
    final navigator = Navigator.of(context);
    final teamsCubit = context.read<TeamsCubit>();
    final fcAccountsCubit = context.read<FcAccountsCubit>();
    final team = await teamsCubit.createTeam(
      name: _nameController.text,
      tag: _tagController.text,
    );
    if (team == null) {
      return;
    }
    for (final accountId in _selectedAccountIds) {
      await fcAccountsCubit.linkToTeam(accountId: accountId, teamId: team.id);
    }
    if (mounted) {
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
        isChildScrollable: true,
        actions: <Widget>[
          AppButton(
            label: l10n.teamCreateAction,
            icon: Icons.add,
            isLoading: state.isSaving,
            onPressed: state.isSaving || _selectedAccountIds.isEmpty
                ? null
                : _submit,
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
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
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
                  validator: (value) =>
                      AppValidators.teamTag(value)?.message(l10n),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.teamCreateFcAccountsSectionTitle,
                  style: context.textStyles.labelSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final account in widget.accounts)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(account.name),
                    value: _selectedAccountIds.contains(account.id),
                    onChanged: state.isSaving
                        ? null
                        : (checked) => setState(() {
                            if (checked ?? false) {
                              _selectedAccountIds.add(account.id);
                            } else {
                              _selectedAccountIds.remove(account.id);
                            }
                          }),
                  ),
              ],
            ),
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
