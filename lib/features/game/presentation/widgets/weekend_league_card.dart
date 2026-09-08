import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_state.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/weekend_league_manual_record_sheet.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Contextual ao Elenco selecionado (Etapa 9) -- o record mostrado troca
/// junto com o elenco, nunca é agregado entre elencos.
class WeekendLeagueCard extends StatelessWidget {
  const WeekendLeagueCard({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<FcAccountsCubit, FcAccountsState>(
        buildWhen: (previous, current) =>
            previous.weekendLeagueEvent != current.weekendLeagueEvent ||
            previous.selectedAccount != current.selectedAccount,
        builder: (context, state) {
          final event = state.weekendLeagueEvent;
          final account = state.selectedAccount;
          if (event == null || account == null) {
            return const SizedBox.shrink();
          }
          return _WeekendLeagueCardBody(event: event, account: account);
        },
      );
}

class _WeekendLeagueCardBody extends StatelessWidget {
  const _WeekendLeagueCardBody({required this.event, required this.account});

  final WeekendLeagueEvent event;
  final FcAccount account;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final record = account.weekendLeagueRecord;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: AppCard(
        onTap: () => showWeekendLeagueManualRecordSheet(
          context: context,
          account: account,
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.emoji_events_outlined,
              size: AppSizing.iconLg,
              color: colors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.weekendLeagueBadge(event.number),
                    style: context.textStyles.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    account.hasWeekendLeagueManualOverride
                        ? l10n.fcAccountWeekendLeagueManualLabel(
                            record.$1,
                            record.$2,
                          )
                        : l10n.weekendLeagueWindow(
                            l10n.historyEntryDate(event.startsAt),
                            l10n.historyEntryDate(event.endsAt),
                          ),
                    style: context.textStyles.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${record.$1}–${record.$2}',
              style: context.textStyles.headlineSmall,
            ),
            const SizedBox(width: AppSpacing.md),
            if (event.isActive)
              AppBadge(
                label: l10n.weekendLeagueActiveBadge,
                tone: AppBadgeTone.success,
              ),
          ],
        ),
      ),
    );
  }
}
