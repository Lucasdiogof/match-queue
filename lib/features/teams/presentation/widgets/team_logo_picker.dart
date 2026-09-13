import 'dart:typed_data';

import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

/// Logo escolhida mas ainda nao enviada -- usado pelo fluxo de criacao de
/// time, que so tem onde fazer upload (o teamId) depois que o time ja
/// existe.
class PickedTeamLogo {
  const PickedTeamLogo({required this.bytes, required this.contentType});

  final Uint8List bytes;
  final String contentType;
}

/// Abre a galeria, ja limita a resolucao/qualidade na propria selecao (sem
/// dependencia nova so pra redimensionar) e devolve bytes + content type.
/// Null se o usuario cancelou.
Future<PickedTeamLogo?> pickTeamLogoBytes() async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 512,
    maxHeight: 512,
    imageQuality: 85,
  );
  if (file == null) {
    return null;
  }
  final bytes = await file.readAsBytes();
  final contentType = switch (file.mimeType) {
    'image/png' => 'image/png',
    'image/webp' => 'image/webp',
    _ => 'image/jpeg',
  };
  return PickedTeamLogo(bytes: bytes, contentType: contentType);
}

/// Fluxo de EDICAO: time ja existe, entao escolher a logo ja envia e ja
/// salva na mesma acao -- nada fica "escolhido mas nao salvo" igual no
/// fluxo de criacao (onde nao ha teamId ainda).
class TeamLogoPicker extends StatelessWidget {
  const TeamLogoPicker({
    required this.teamId,
    required this.isSaving,
    required this.preview,
    super.key,
  });

  final String teamId;
  final bool isSaving;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: <Widget>[
        preview,
        const SizedBox(height: AppSpacing.sm),
        AppButton.ghost(
          label: l10n.teamLogoChangeAction,
          icon: Icons.photo_camera_outlined,
          onPressed: isSaving ? null : () => _pickAndUpload(context),
        ),
      ],
    );
  }

  Future<void> _pickAndUpload(BuildContext context) async {
    final picked = await pickTeamLogoBytes();
    if (picked == null || !context.mounted) {
      return;
    }
    final cubit = context.read<TeamsCubit>();
    final ok = await cubit.uploadAndSetTeamLogo(
      teamId: teamId,
      bytes: picked.bytes,
      contentType: picked.contentType,
    );
    if (!ok && context.mounted) {
      final failure = cubit.state.actionFailure;
      if (failure != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.localizedMessage(context.l10n))),
        );
      }
    }
  }
}
