import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_state.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/fc_account_onboarding_card.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/fc_account_switcher_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Identidade FC no topo do Inicio. A Home e contextual a Conta FC, nao ao
/// Time: Rivals e Weekend League pertencem a conta e existem antes de
/// qualquer time. Zero contas mostra o convite de cadastro (mesmo card do
/// Controle, nao uma copia); varias contas mostram a ativa e a troca.
class HomeFcAccountCard extends StatelessWidget {
  const HomeFcAccountCard({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<FcAccountsCubit, FcAccountsState>(
        buildWhen: (previous, current) =>
            previous.selectedAccount != current.selectedAccount ||
            previous.accounts.length != current.accounts.length,
        builder: (context, state) {
          if (!state.hasAccounts) {
            return const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.xl),
              child: FcAccountOnboardingCard(),
            );
          }

          final account = state.selectedAccount;
          if (account == null) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: _ActiveAccountCard(
              account: account,
              accounts: state.accounts,
              selectedAccountId: state.selectedAccountId,
            ),
          );
        },
      );
}

class _ActiveAccountCard extends StatelessWidget {
  const _ActiveAccountCard({
    required this.account,
    required this.accounts,
    required this.selectedAccountId,
  });

  final FcAccount account;
  final List<FcAccount> accounts;
  final String? selectedAccountId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final teamCount = account.teamIds.length;
    final canSwitch = accounts.length > 1;

    return AppCard(
      variant: AppCardVariant.elevated,
      child: Row(
        children: <Widget>[
          Container(
            width: AppSizing.iconXl,
            height: AppSizing.iconXl,
            decoration: BoxDecoration(
              color: colors.surfaceHighest,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(account.name),
              style: context.textStyles.titleSmall,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.homeFcAccountEyebrow,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(account.name, style: context.textStyles.titleMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  teamCount == 0
                      ? l10n.homeFcAccountNoTeams
                      : l10n.homeFcAccountTeamCount(teamCount),
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (canSwitch)
            AppButton.ghost(
              label: l10n.homeFcAccountSwitchAction,
              onPressed: () => showFcAccountSwitcherSheet(
                context: context,
                accounts: accounts,
                selectedAccountId: selectedAccountId,
              ),
            ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}
