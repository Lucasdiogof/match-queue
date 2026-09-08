import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/game/domain/entities/game_result.dart';
import 'package:fifa_queue/features/game/domain/repositories/game_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Editor de resultado disponivel a qualquer momento depois de FINISHED,
/// sem janela de tempo (Etapa 12) -- diferente do FinishMatchSheet, que so
/// funciona enquanto a partida ainda esta IN_MATCH.
Future<bool?> showEditMatchResultSheet({
  required BuildContext context,
  required String matchId,
  GameResult? initialResult,
  int? initialGoalsFor,
  int? initialGoalsAgainst,
}) => showAppBottomSheet<bool>(
  context: context,
  builder: (sheetContext) => _EditMatchResultForm(
    matchId: matchId,
    initialResult: initialResult,
    initialGoalsFor: initialGoalsFor,
    initialGoalsAgainst: initialGoalsAgainst,
  ),
);

class _EditMatchResultForm extends StatefulWidget {
  const _EditMatchResultForm({
    required this.matchId,
    this.initialResult,
    this.initialGoalsFor,
    this.initialGoalsAgainst,
  });

  final String matchId;
  final GameResult? initialResult;
  final int? initialGoalsFor;
  final int? initialGoalsAgainst;

  @override
  State<_EditMatchResultForm> createState() => _EditMatchResultFormState();
}

class _EditMatchResultFormState extends State<_EditMatchResultForm> {
  late final TextEditingController _forController = TextEditingController(
    text: widget.initialGoalsFor?.toString() ?? '',
  );
  late final TextEditingController _againstController = TextEditingController(
    text: widget.initialGoalsAgainst?.toString() ?? '',
  );
  bool _isSaving = false;
  AppFailure? _failure;

  @override
  void dispose() {
    _forController.dispose();
    _againstController.dispose();
    super.dispose();
  }

  Future<void> _submitScore() async {
    final goalsFor = int.tryParse(_forController.text);
    final goalsAgainst = int.tryParse(_againstController.text);
    if (goalsFor == null || goalsAgainst == null) {
      return;
    }
    if (goalsFor == goalsAgainst) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.finishMatchDrawError)),
      );
      return;
    }
    await _submit(goalsFor: goalsFor, goalsAgainst: goalsAgainst);
  }

  Future<void> _submitQuick(GameResult result) => _submit(result: result);

  Future<void> _submit({
    GameResult? result,
    int? goalsFor,
    int? goalsAgainst,
  }) async {
    setState(() {
      _isSaving = true;
      _failure = null;
    });
    try {
      await getIt<GameRepository>().updateMatchResult(
        matchId: widget.matchId,
        result: result,
        goalsFor: goalsFor,
        goalsAgainst: goalsAgainst,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on AppFailure catch (failure) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _failure = failure;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppBottomSheet(
      title: l10n.editMatchResultSheetTitle,
      subtitle: l10n.editMatchResultSheetMessage,
      actions: <Widget>[
        AppButton(
          label: l10n.editMatchResultSubmitAction,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _submitScore,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            Expanded(
              child: AppButton.secondary(
                label: l10n.pendingMatchLossAction,
                isLoading: _isSaving,
                onPressed: _isSaving
                    ? null
                    : () => _submitQuick(GameResult.loss),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppButton.secondary(
                label: l10n.pendingMatchWinAction,
                isLoading: _isSaving,
                onPressed: _isSaving
                    ? null
                    : () => _submitQuick(GameResult.win),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton.ghost(
          label: l10n.actionClose,
          expanded: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_failure != null) ...<Widget>[
            AppBanner(
              tone: AppBannerTone.danger,
              message: _failure!.localizedMessage(l10n),
            ),
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
