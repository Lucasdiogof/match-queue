import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/profiles/domain/entities/profile.dart';
import 'package:fifa_queue/features/profiles/presentation/cubit/profiles_cubit.dart';
import 'package:fifa_queue/features/profiles/presentation/widgets/archive_profile_sheet.dart';
import 'package:fifa_queue/features/profiles/presentation/widgets/create_profile_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showProfileSwitcherSheet({
  required BuildContext context,
  required List<Profile> profiles,
  required String? selectedProfileId,
}) async {
  final cubit = context.read<ProfilesCubit>();
  await showAppBottomSheet<void>(
    context: context,
    builder: (sheetContext) => BlocProvider<ProfilesCubit>.value(
      value: cubit,
      child: AppBottomSheet(
        title: context.l10n.profileSwitchTitle,
        // A lista cresce com o numero de contas; sem scroll, quem tem varias
        // perde as ultimas linhas e o botao de criar atras da navegacao.
        isChildScrollable: true,
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            for (final profile in profiles)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _ProfileRow(
                  profile: profile,
                  isSelected: profile.id == selectedProfileId,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    cubit.selectProfile(profile.id);
                  },
                  onDelete: () async {
                    final archived = await showArchiveProfileSheet(
                      context: sheetContext,
                      profileId: profile.id,
                      profileName: profile.name,
                    );
                    // A lista deste sheet e um snapshot passado por
                    // parametro (nao um BlocBuilder ao vivo) -- mais simples
                    // fechar e deixar quem abriu re-renderizar com a lista
                    // atualizada do que tentar remover a linha aqui.
                    if (archived && sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                ),
              ),
            AppButton.ghost(
              label: context.l10n.profileSwitchCreateAction,
              icon: Icons.add,
              expanded: true,
              onPressed: () async {
                Navigator.of(sheetContext).pop();
                if (context.mounted) {
                  await showCreateProfileSheet(context);
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.profile,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  final Profile profile;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppCard(
      variant: isSelected ? AppCardVariant.elevated : AppCardVariant.outlined,
      onTap: onTap,
      borderColor: isSelected ? colors.borderStrong : null,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: <Widget>[
          AppAvatar(
            label: profile.name,
            imageUrl: profile.avatarUrl,
            size: AppSizing.avatarMd,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(profile.name, style: context.textStyles.titleSmall),
          ),
          if (isSelected)
            Icon(Icons.check_circle, color: colors.textPrimary)
          else
            Icon(Icons.chevron_right, color: colors.textTertiary),
          AppIconButton(
            icon: Icons.delete_outline,
            tooltip: context.l10n.profileArchiveAction,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
