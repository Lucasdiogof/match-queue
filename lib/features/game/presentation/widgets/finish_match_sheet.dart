import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/game/presentation/cubit/pending_match_cubit.dart';
import 'package:fifa_queue/features/game/presentation/cubit/pending_match_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Retorna true quando o placar foi salvo com sucesso -- o chamador decide
/// se oferece o detalhamento por jogador em seguida, com o BuildContext da
/// própria página (o da sheet já estará desmontado nesse ponto).
Future<bool?> showFinishMatchSheet(BuildContext context) =>
    showAppBottomSheet<bool>(
      context: context,
      builder: (sheetContext) => BlocProvider.value(
        value: context.read<PendingMatchCubit>(),
        child: const _FinishMatchForm(),
      ),
    );

class _FinishMatchForm extends StatefulWidget {
  const _FinishMatchForm();

  @override
  State<_FinishMatchForm> createState() => _FinishMatchFormState();
}

class _FinishMatchFormState extends State<_FinishMatchForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _forController = TextEditingController();
  final TextEditingController _againstController = TextEditingController();
  String? _draftError;

  @override
  void dispose() {
    _forController.dispose();
    _againstController.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    final l10n = context.l10n;
    setState(() => _draftError = null);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final goalsFor = int.parse(_forController.text);
    final goalsAgainst = int.parse(_againstController.text);
    if (goalsFor == goalsAgainst) {
      setState(() => _draftError = l10n.finishMatchDrawError);
      return;
    }
    final cubit = context.read<PendingMatchCubit>();
    final ok = await cubit.finish(
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
    );
    if (!context.mounted) {
      return;
    }
    if (ok) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<PendingMatchCubit, PendingMatchState>(
      builder: (context, state) => AppBottomSheet(
        title: l10n.finishMatchSheetTitle,
        subtitle: l10n.finishMatchSheetMessage,
        actions: <Widget>[
          AppButton(
            label: l10n.finishMatchSubmitAction,
            isLoading: state.isSaving,
            onPressed: state.isSaving ? null : () => _submit(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.ghost(
            label: l10n.actionClose,
            expanded: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (state.actionFailure != null) ...<Widget>[
                AppBanner(
                  tone: AppBannerTone.danger,
                  message: state.actionFailure!.localizedMessage(l10n),
                ),
                const SizedBox(height: AppSpacing.lg),
              ] else if (_draftError != null) ...<Widget>[
                AppBanner(tone: AppBannerTone.danger, message: _draftError!),
                const SizedBox(height: AppSpacing.lg),
              ],
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppTextField(
                      label: l10n.finishMatchGoalsForLabel,
                      controller: _forController,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      autofocus: true,
                      validator: (value) =>
                          (int.tryParse(value ?? '') ?? -1) < 0
                          ? l10n.finishMatchGoalsRequired
                          : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppTextField(
                      label: l10n.finishMatchGoalsAgainstLabel,
                      controller: _againstController,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(context),
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
