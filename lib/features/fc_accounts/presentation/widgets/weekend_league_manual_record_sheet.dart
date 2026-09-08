import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showWeekendLeagueManualRecordSheet({
  required BuildContext context,
  required FcAccount account,
}) async {
  final cubit = context.read<FcAccountsCubit>();
  cubit.clearActionFailure();
  await showAppBottomSheet<void>(
    context: context,
    builder: (sheetContext) => BlocProvider<FcAccountsCubit>.value(
      value: cubit,
      child: _ManualRecordForm(account: account),
    ),
  );
}

class _ManualRecordForm extends StatefulWidget {
  const _ManualRecordForm({required this.account});

  final FcAccount account;

  @override
  State<_ManualRecordForm> createState() => _ManualRecordFormState();
}

class _ManualRecordFormState extends State<_ManualRecordForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _winsController = TextEditingController(
    text: '${widget.account.weekendLeagueRecord.$1}',
  );
  late final TextEditingController _lossesController = TextEditingController(
    text: '${widget.account.weekendLeagueRecord.$2}',
  );

  @override
  void dispose() {
    _winsController.dispose();
    _lossesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final navigator = Navigator.of(context);
    final ok = await context
        .read<FcAccountsCubit>()
        .setWeekendLeagueManualRecord(
          accountId: widget.account.id,
          wins: int.parse(_winsController.text),
          losses: int.parse(_lossesController.text),
        );
    if (ok && mounted) {
      navigator.pop();
    }
  }

  Future<void> _clear() async {
    final navigator = Navigator.of(context);
    final ok = await context
        .read<FcAccountsCubit>()
        .clearWeekendLeagueManualRecord(widget.account.id);
    if (ok && mounted) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<FcAccountsCubit, FcAccountsState>(
      builder: (context, state) => AppBottomSheet(
        title: l10n.fcAccountWeekendLeagueSheetTitle,
        actions: <Widget>[
          AppButton(
            label: l10n.actionSave,
            isLoading: state.isSaving,
            onPressed: state.isSaving ? null : _submit,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (widget.account.hasWeekendLeagueManualOverride)
            AppButton.secondary(
              label: l10n.fcAccountWeekendLeagueClearAction,
              isLoading: state.isSaving,
              onPressed: state.isSaving ? null : _clear,
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
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppTextField(
                      label: l10n.fcAccountWeekendLeagueWinsLabel,
                      controller: _winsController,
                      enabled: !state.isSaving,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) =>
                          (int.tryParse(value ?? '') ?? -1) < 0
                          ? l10n.finishMatchGoalsRequired
                          : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppTextField(
                      label: l10n.fcAccountWeekendLeagueLossesLabel,
                      controller: _lossesController,
                      enabled: !state.isSaving,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: (value) =>
                          (int.tryParse(value ?? '') ?? -1) < 0
                          ? l10n.finishMatchGoalsRequired
                          : null,
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
