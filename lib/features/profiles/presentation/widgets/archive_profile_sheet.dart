import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/profiles/presentation/cubit/profiles_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Confirmacao pra excluir uma Conta FC (nunca a conta de login -- ver
/// DeleteAccountPage pra essa). Devolve true quando a exclusao foi
/// concluida com sucesso (o chamador pode usar isso pra, por exemplo,
/// fechar uma tela de detalhe que nao faz mais sentido existir).
Future<bool> showArchiveProfileSheet({
  required BuildContext context,
  required String profileId,
  required String profileName,
}) async {
  final cubit = context.read<ProfilesCubit>();
  final result = await showAppBottomSheet<bool>(
    context: context,
    builder: (sheetContext) => BlocProvider<ProfilesCubit>.value(
      value: cubit,
      child: _ArchiveProfileSheetBody(
        profileId: profileId,
        profileName: profileName,
      ),
    ),
  );
  return result ?? false;
}

class _ArchiveProfileSheetBody extends StatefulWidget {
  const _ArchiveProfileSheetBody({
    required this.profileId,
    required this.profileName,
  });

  final String profileId;
  final String profileName;

  @override
  State<_ArchiveProfileSheetBody> createState() =>
      _ArchiveProfileSheetBodyState();
}

class _ArchiveProfileSheetBodyState extends State<_ArchiveProfileSheetBody> {
  bool _isSubmitting = false;
  AppFailure? _failure;

  Future<void> _confirm() async {
    setState(() {
      _isSubmitting = true;
      _failure = null;
    });
    final cubit = context.read<ProfilesCubit>();
    final ok = await cubit.archiveProfile(widget.profileId);
    if (!mounted) {
      return;
    }
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _isSubmitting = false;
      _failure = cubit.state.actionFailure;
    });
    cubit.clearActionFailure();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failure = _failure;

    return AppBottomSheet(
      title: l10n.profileArchiveConfirmTitle,
      subtitle: l10n.profileArchiveConfirmMessage(widget.profileName),
      actions: <Widget>[
        if (failure != null) ...<Widget>[
          AppBanner(
            tone: AppBannerTone.danger,
            message: failure.localizedMessage(l10n),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        AppButton.danger(
          label: l10n.profileArchiveAction,
          icon: Icons.delete_outline,
          expanded: true,
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : _confirm,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton.ghost(
          label: l10n.actionCancel,
          expanded: true,
          onPressed: _isSubmitting
              ? null
              : () => Navigator.of(context).pop(false),
        ),
      ],
      child: const SizedBox.shrink(),
    );
  }
}
