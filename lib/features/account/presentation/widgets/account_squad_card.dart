import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/account/domain/entities/account.dart';
import 'package:fifa_queue/features/account/presentation/cubit/account_cubit.dart';
import 'package:fifa_queue/features/account/presentation/cubit/account_state.dart';
import 'package:fifa_queue/features/account/presentation/widgets/platform_picker_sheet.dart';
import 'package:fifa_queue/features/fc_squads/presentation/cubit/fc_squads_cubit.dart';
import 'package:fifa_queue/features/fc_squads/presentation/cubit/fc_squads_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Plataformas e Elenco num card so, na primeira dobra do Jogar. Nao ha mais
/// linha de "Conta" aqui: com 1 login = 1 usuario, dizer de quem e a conta
/// virou informacao morta -- e o antigo toque dessa linha (trocar de conta)
/// deixou de existir junto com o conceito.
///
/// Cada linha tem o proprio toque: Plataformas abre o mesmo seletor da tela
/// de Conta, Elenco vai direto pra montar/editar escalacao.
class AccountSquadCard extends StatelessWidget {
  const AccountSquadCard({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<AccountCubit, AccountState>(
    buildWhen: (previous, current) => previous.account != current.account,
    builder: (context, accountState) {
      final account = accountState.account;
      if (account == null) {
        return const SizedBox.shrink();
      }
      final colors = context.colors;

      return AppCard(
        variant: AppCardVariant.elevated,
        accent: AppCardAccent.left,
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _PlatformRow(account: account),
            Divider(height: 1, thickness: 1, color: colors.borderSubtle),
            const _SquadRow(),
          ],
        ),
      );
    },
  );
}

class _PlatformRow extends StatelessWidget {
  const _PlatformRow({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return InkWell(
      onTap: () => showPlatformPickerSheet(
        context: context,
        selected: account.platforms,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: _Field(
                label: l10n.accountPlatformLabel,
                value: account.platforms.isEmpty
                    ? l10n.accountPlatformNone
                    : account.platforms
                          .map((platform) => platform.displayLabel)
                          .join(' · '),
                isMuted: account.platforms.isEmpty,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l10n.actionEdit,
              style: context.textStyles.labelSmall?.copyWith(
                color: colors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: AppSizing.iconMd,
              color: colors.accent,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ),
      ),
    );
  }
}

class _SquadRow extends StatelessWidget {
  const _SquadRow();

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<FcSquadsCubit, FcSquadsState>(
    builder: (context, state) {
      final l10n = context.l10n;
      final colors = context.colors;
      final squad = state.selectedSquad;
      // Só formação escolhida e nenhum titular ainda não é "um elenco" pra
      // quem olha este card de relance -- trata igual a nenhum elenco, e a
      // química nem entra aqui (é detalhe do builder, não deste resumo).
      final hasCompleteSquad = squad != null && squad.isComplete;

      // Um elenco por conta e a regra de produto daqui pra frente. O schema
      // ainda permite varios (fc_squads nao tem unico por conta), entao aqui
      // mostramos o selecionado como "o" elenco e a lista completa continua
      // na tela da Conta. Fechar isso no dominio fica pra etapa funcional.
      final value = !hasCompleteSquad
          ? l10n.playSquadEmpty
          : <String>[
              squad.formationCode,
              squad.overall == null
                  ? l10n.squadOverallUnknown
                  : l10n.squadOverallValue(squad.overall!),
            ].join(' · ');

      return InkWell(
        onTap: state.isSaving
            ? null
            : () => squad == null
                  ? _createSquad(context)
                  : context.pushNamed(
                      AppRoutes.squadBuilder.name,
                      pathParameters: <String, String>{
                        AppRoutes.squadIdParam: squad.id,
                      },
                    ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _Field(
                  label: l10n.squadLabel,
                  value: value,
                  isMuted: !hasCompleteSquad,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                !hasCompleteSquad
                    ? l10n.playSquadBuildAction
                    : l10n.playSquadEditAction,
                style: context.textStyles.labelSmall?.copyWith(
                  color: colors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: AppSizing.iconMd,
                color: colors.accent,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ),
        ),
      );
    },
  );

  // Sem nome nem formação a pedir: cria direto com o default (4-4-2) e já
  // entra no builder, que é onde a formação se escolhe (ao vivo).
  Future<void> _createSquad(BuildContext context) async {
    final cubit = context.read<FcSquadsCubit>();
    final squad = await cubit.createSquad();
    if (squad == null || !context.mounted) {
      return;
    }
    await context.pushNamed(
      AppRoutes.squadBuilder.name,
      pathParameters: <String, String>{AppRoutes.squadIdParam: squad.id},
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    this.isMuted = false,
  });

  final String label;
  final String value;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textStyles.labelSmall?.copyWith(
            color: colors.textTertiary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          // Uma linha e elipse: nome de conta longo nao pode empurrar o
          // card, e a tela precisa caber num Android pequeno.
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textStyles.titleSmall?.copyWith(
            color: isMuted ? colors.textSecondary : colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
