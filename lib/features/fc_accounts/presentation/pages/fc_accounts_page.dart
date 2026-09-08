import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_state.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/create_fc_account_sheet.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/rivals_division_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class FcAccountsPage extends StatelessWidget {
  const FcAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: AppAppBar(
        title: l10n.fcAccountsPageTitle,
        subtitle: l10n.fcAccountsPageSubtitle,
      ),
      body: BlocBuilder<FcAccountsCubit, FcAccountsState>(
        builder: (context, state) {
          if (state.isLoading && !state.hasAccounts) {
            return const AppLoading();
          }
          if (!state.hasAccounts) {
            return _EmptyState(
              onCreate: () => showCreateFcAccountSheet(context),
            );
          }
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            children: <Widget>[
              for (final account in state.accounts)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _FcAccountCard(account: account),
                ),
              AppButton.secondary(
                label: l10n.fcAccountCreateAction,
                icon: Icons.add,
                onPressed: () => showCreateFcAccountSheet(context),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.sports_esports_outlined,
              size: AppSizing.iconXl,
              color: context.colors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.fcAccountsEmptyTitle,
              textAlign: TextAlign.center,
              style: context.textStyles.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.fcAccountsEmptyMessage,
              textAlign: TextAlign.center,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: l10n.fcAccountCreateAction,
              icon: Icons.add,
              onPressed: onCreate,
            ),
          ],
        ),
      ),
    );
  }
}

class _FcAccountCard extends StatelessWidget {
  const _FcAccountCard({required this.account});

  final FcAccount account;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final record = account.weekendLeagueRecord;

    return AppCard(
      onTap: () => context.push(AppRoutes.fcAccountDetailLocation(account.id)),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(account.name, style: context.textStyles.titleMedium),
                const SizedBox(height: AppSpacing.xxs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xxs,
                  children: <Widget>[
                    if (account.rivalsDivision != null)
                      AppBadge(label: account.rivalsDivision!.label(l10n)),
                    AppBadge(
                      label: '${record.$1}–${record.$2}',
                      tone: AppBadgeTone.neutral,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colors.textTertiary),
        ],
      ),
    );
  }
}
