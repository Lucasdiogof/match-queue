import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_event.dart';
import 'package:fifa_queue/features/game/presentation/cubit/pending_match_cubit.dart';
import 'package:fifa_queue/features/game/presentation/cubit/pending_match_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WeekendLeagueCard extends StatelessWidget {
  const WeekendLeagueCard({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PendingMatchCubit, PendingMatchState>(
        buildWhen: (previous, current) =>
            previous.weekendLeagueEvent != current.weekendLeagueEvent ||
            previous.weekendLeagueRecord != current.weekendLeagueRecord,
        builder: (context, state) {
          final event = state.weekendLeagueEvent;
          if (event == null) {
            return const SizedBox.shrink();
          }
          return _WeekendLeagueCardBody(
            event: event,
            record: state.weekendLeagueRecord,
          );
        },
      );
}

class _WeekendLeagueCardBody extends StatelessWidget {
  const _WeekendLeagueCardBody({required this.event, this.record});

  final WeekendLeagueEvent event;
  final WeekendLeagueRecord? record;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: AppCard(
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
                    l10n.weekendLeagueWindow(
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
            if (record != null) ...<Widget>[
              Text(
                '${record!.wins}–${record!.losses}',
                style: context.textStyles.headlineSmall,
              ),
              const SizedBox(width: AppSpacing.md),
            ],
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
