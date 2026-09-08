import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_state.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/fc_account_switcher_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Seletor de Elenco na tela de Jogar -- só aparece quando há elencos, o
/// onboarding vazio (ver [FcAccountOnboardingCard]) cobre o caso zero.
class FcAccountSelectorRow extends StatelessWidget {
  const FcAccountSelectorRow({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<FcAccountsCubit, FcAccountsState>(
        buildWhen: (previous, current) =>
            previous.accounts != current.accounts ||
            previous.selectedAccountId != current.selectedAccountId,
        builder: (context, state) {
          final account = state.selectedAccount;
          if (!state.hasAccounts || account == null) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              onTap: () => showFcAccountSwitcherSheet(
                context: context,
                accounts: state.accounts,
                selectedAccountId: state.selectedAccountId,
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.sports_esports_outlined,
                    size: AppSizing.iconMd,
                    color: context.colors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      account.name,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.titleSmall,
                    ),
                  ),
                  Icon(
                    Icons.unfold_more,
                    size: AppSizing.iconMd,
                    color: context.colors.textTertiary,
                  ),
                ],
              ),
            ),
          );
        },
      );
}
