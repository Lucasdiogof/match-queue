import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_state.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/fc_account_switcher_sheet.dart';
import 'package:fifa_queue/features/fc_squads/presentation/cubit/fc_squads_cubit.dart';
import 'package:fifa_queue/features/fc_squads/presentation/cubit/fc_squads_state.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/squad_name_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Conta e Elenco num unico card, porque sao uma coisa so: o Elenco pertence
/// a Conta e nao existe fora dela. Antes eram dois cards grandes empilhados,
/// o que sugeria duas entidades independentes e comia a primeira dobra do
/// Jogar -- justamente onde o matchmaking precisa estar.
///
/// Cada metade tem o proprio toque, sem acao de card inteiro: a de cima
/// (Conta) abre o troca-conta -- o mesmo que o botao discreto ja fazia, so
/// que o toque nao precisa mais acertar so o icone. A de baixo (Elenco) vai
/// direto pra montar/editar escalacao, que e o que o texto da linha ja
/// promete.
class AccountSquadCard extends StatelessWidget {
  const AccountSquadCard({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<FcAccountsCubit, FcAccountsState>(
        buildWhen: (previous, current) =>
            previous.accounts != current.accounts ||
            previous.selectedAccountId != current.selectedAccountId,
        builder: (context, accountsState) {
          final account = accountsState.selectedAccount;
          if (!accountsState.hasAccounts || account == null) {
            return const SizedBox.shrink();
          }
          final l10n = context.l10n;
          final colors = context.colors;

          return AppCard(
            variant: AppCardVariant.elevated,
            accent: AppCardAccent.left,
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                InkWell(
                  onTap: () => showFcAccountSwitcherSheet(
                    context: context,
                    accounts: accountsState.accounts,
                    selectedAccountId: accountsState.selectedAccountId,
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
                            label: l10n.playAccountLabel,
                            value: account.name,
                          ),
                        ),
                        AppIconButton(
                          icon: Icons.swap_horiz,
                          tooltip: l10n.fcAccountSwitchTitle,
                          variant: AppIconButtonVariant.surface,
                          onPressed: () => showFcAccountSwitcherSheet(
                            context: context,
                            accounts: accountsState.accounts,
                            selectedAccountId: accountsState.selectedAccountId,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: AppSizing.iconMd,
                          color: colors.textTertiary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, thickness: 1, color: colors.borderSubtle),
                const _SquadRow(),
              ],
            ),
          );
        },
      );
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
                  ? _createSquad(context, state)
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

  // Mesmo fluxo de squads_section.dart: pede nome+formacao, cria, e deixa o
  // BlocBuilder re-renderizar com o elenco novo -- o usuario toca de novo
  // pra entrar no builder, sem navegacao automatica que ele nao pediu.
  Future<void> _createSquad(BuildContext context, FcSquadsState state) async {
    final l10n = context.l10n;
    final cubit = context.read<FcSquadsCubit>();
    final result = await showSquadNameSheet(
      context: context,
      title: l10n.squadCreateTitle,
      subtitle: l10n.squadCreateSubtitle,
      formations: state.formations,
    );
    if (result == null || result.formationCode == null) {
      return;
    }
    await cubit.createSquad(
      name: result.name,
      formationCode: result.formationCode!,
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
