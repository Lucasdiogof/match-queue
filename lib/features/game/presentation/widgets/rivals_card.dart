import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_state.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/pages/rivals_detail_page.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/rivals_division_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Resumo de Division Rivals na Home (gameplay flows refresh, item 6) --
/// mesma estrutura de [WeekendLeagueCard]: card só de leitura que abre
/// [RivalsDetailPage], nunca um formulário embutido. Contextual à Conta FC
/// selecionada, igual ao card de Weekend League.
class RivalsCard extends StatelessWidget {
  const RivalsCard({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<FcAccountsCubit, FcAccountsState>(
        buildWhen: (previous, current) =>
            previous.selectedAccount != current.selectedAccount,
        builder: (context, state) {
          final account = state.selectedAccount;
          if (account == null) {
            return const SizedBox.shrink();
          }
          return _RivalsCardBody(account: account);
        },
      );
}

class _RivalsCardBody extends StatelessWidget {
  const _RivalsCardBody({required this.account});

  final FcAccount account;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final division = account.rivalsDivision;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: AppCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => RivalsDetailPage(account: account),
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.military_tech_outlined,
              size: AppSizing.iconLg,
              color: colors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.rivalsSectionTitle,
                    style: context.textStyles.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    division == null
                        ? l10n.rivalsNoDivisionLabel
                        : division.label(l10n),
                    style: context.textStyles.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }
}
