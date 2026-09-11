import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/lineup_draft.dart';
import 'package:fifa_queue/features/fc_squads/presentation/cubit/squad_builder_cubit.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/manager_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Tecnico do Elenco, logo abaixo do campo.
///
/// Fora do campo de proposito: ele nao disputa espaco com os 11, e o campo
/// fica sendo so a escalacao. Tocar abre o picker que ja existia.
///
/// Sem imagem por decisao de DADO: `fc_managers.image_url` esta vazia, e a
/// coluna e ambigua (nao diz se guardaria carta ou retrato). Ate isso estar
/// resolvido, o slot usa um monograma -- melhor do que assumir formato e
/// errar como ja erramos no avatar do perfil publico.
class LineupManagerSlot extends StatelessWidget {
  const LineupManagerSlot({required this.draft, super.key});

  final LineupDraft draft;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final cubit = context.read<SquadBuilderCubit>();
    final manager = draft.manager;
    final league = draft.managerLeague;

    return AppCard(
      onTap: () async {
        final selection = await showManagerPickerSheet(
          context: context,
          currentManager: manager,
          currentLeague: league,
        );
        if (selection != null) {
          // So rascunho: o tecnico e a liga dele entram no mesmo save do
          // resto da escalacao.
          cubit.setManager(
            manager: selection.manager,
            league: selection.league,
          );
        }
      },
      child: Row(
        children: <Widget>[
          Container(
            width: AppSizing.iconXl,
            height: AppSizing.iconXl,
            decoration: BoxDecoration(
              color: colors.surfaceHighest,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: colors.borderSubtle),
            ),
            alignment: Alignment.center,
            child: manager == null
                ? Icon(
                    Icons.person_outline,
                    size: AppSizing.iconMd,
                    color: colors.textTertiary,
                  )
                : Text(
                    manager.name.isEmpty ? '?' : manager.name[0].toUpperCase(),
                    style: context.textStyles.titleSmall,
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  l10n.squadManagerLabel.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: colors.textTertiary,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  manager?.name ?? l10n.squadManagerEmpty,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleSmall?.copyWith(
                    color: manager == null
                        ? colors.textSecondary
                        : colors.textPrimary,
                  ),
                ),
                if (league != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    league.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: AppSizing.iconMd,
            color: colors.textTertiary,
          ),
        ],
      ),
    );
  }
}
