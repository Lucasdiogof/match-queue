import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/profiles/presentation/cubit/profiles_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_logo_picker.dart'
    show pickTeamLogoBytes;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Foto da Conta FC -- mesmo padrao do TeamLogoPicker (escolher ja envia e
/// ja salva, sem estado intermediario "escolhido mas nao salvo"). Reusa
/// [pickTeamLogoBytes]: a escolha de imagem (galeria, resize, content type)
/// nao tem nada de especifico de time, so o nome ficou historico.
class ProfileAvatarPicker extends StatelessWidget {
  const ProfileAvatarPicker({
    required this.profileId,
    required this.isSaving,
    required this.hasAvatar,
    required this.preview,
    super.key,
  });

  final String profileId;
  final bool isSaving;
  final bool hasAvatar;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: <Widget>[
        preview,
        const SizedBox(height: AppSpacing.sm),
        AppButton.ghost(
          label: l10n.profileAvatarChangeAction,
          icon: Icons.photo_camera_outlined,
          onPressed: isSaving ? null : () => _pickAndUpload(context),
        ),
        if (hasAvatar)
          AppButton.ghost(
            label: l10n.profileAvatarRemoveAction,
            icon: Icons.delete_outline,
            onPressed: isSaving ? null : () => _remove(context),
          ),
      ],
    );
  }

  Future<void> _pickAndUpload(BuildContext context) async {
    final picked = await pickTeamLogoBytes();
    if (picked == null || !context.mounted) {
      return;
    }
    final cubit = context.read<ProfilesCubit>();
    final ok = await cubit.uploadAndSetAvatar(
      profileId: profileId,
      bytes: picked.bytes,
      contentType: picked.contentType,
    );
    if (context.mounted) {
      _showFailureIfAny(context, cubit, ok);
    }
  }

  Future<void> _remove(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showAppConfirm(
      context: context,
      title: l10n.profileAvatarRemoveConfirmTitle,
      message: l10n.profileAvatarRemoveConfirmMessage,
      confirmLabel: l10n.profileAvatarRemoveAction,
      cancelLabel: l10n.actionCancel,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    final cubit = context.read<ProfilesCubit>();
    final ok = await cubit.removeAvatar(profileId);
    if (context.mounted) {
      _showFailureIfAny(context, cubit, ok);
    }
  }

  void _showFailureIfAny(BuildContext context, ProfilesCubit cubit, bool ok) {
    if (ok || !context.mounted) {
      return;
    }
    final failure = cubit.state.actionFailure;
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.localizedMessage(context.l10n))),
      );
    }
  }
}
