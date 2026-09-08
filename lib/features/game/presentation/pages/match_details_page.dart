import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/game/domain/entities/game_match_details.dart';
import 'package:fifa_queue/features/game/domain/entities/game_result.dart';
import 'package:fifa_queue/features/game/domain/repositories/game_repository.dart';
import 'package:fifa_queue/features/game/presentation/pages/player_stats_editor_page.dart';
import 'package:fifa_queue/features/game/presentation/widgets/edit_match_result_sheet.dart';
import 'package:fifa_queue/features/matchmaking/presentation/widgets/game_mode_selector.dart';
import 'package:flutter/material.dart';

/// Tela de detalhe de uma partida a partir do Historico -- funciona tanto
/// pra propria partida (com CTAs de editar) quanto pra de um companheiro de
/// time (so leitura, is_owner vem do backend). Partida sem squad_snapshot
/// nunca mostra a secao de gols/assistencias por jogador.
class MatchDetailsPage extends StatefulWidget {
  const MatchDetailsPage({required this.matchId, super.key});

  final String matchId;

  @override
  State<MatchDetailsPage> createState() => _MatchDetailsPageState();
}

class _MatchDetailsPageState extends State<MatchDetailsPage> {
  late Future<GameMatchDetails> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = getIt<GameRepository>().fetchMatchDetails(widget.matchId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: AppAppBar(title: l10n.matchDetailsTitle),
      body: FutureBuilder<GameMatchDetails>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoading();
          }
          final error = snapshot.error;
          if (error != null) {
            return AppErrorState(
              title: l10n.errorUnexpected,
              message: error is AppFailure
                  ? error.localizedMessage(l10n)
                  : l10n.errorUnexpected,
              retryLabel: l10n.actionRetry,
              onRetry: () => setState(_load),
            );
          }
          final details = snapshot.data;
          if (details == null) {
            return const SizedBox.shrink();
          }
          return _MatchDetailsBody(
            details: details,
            onChanged: () => setState(_load),
          );
        },
      ),
    );
  }
}

class _MatchDetailsBody extends StatelessWidget {
  const _MatchDetailsBody({required this.details, required this.onChanged});

  final GameMatchDetails details;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.xl,
    ),
    children: <Widget>[
      _HeaderCard(details: details),
      const SizedBox(height: AppSpacing.lg),
      _ResultCard(details: details, onChanged: onChanged),
      if (details.canDetailPlayers) ...<Widget>[
        const SizedBox(height: AppSpacing.lg),
        _PlayerStatsCard(details: details, onChanged: onChanged),
      ],
    ],
  );
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.details});

  final GameMatchDetails details;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final snapshot = details.squadSnapshot;

    return AppCard(
      variant: AppCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  details.gameMode.label(l10n),
                  style: context.textStyles.titleMedium,
                ),
              ),
              AppBadge(label: details.status),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${l10n.historyEntryDate(details.startedAt)} · '
            '${l10n.historyEntryTime(details.startedAt)}',
            style: context.textStyles.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          if (details.fcAccountName != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              details.fcAccountName!,
              style: context.textStyles.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
          if (snapshot != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              l10n.squadSummaryLabel(snapshot.name, snapshot.formationCode),
              style: context.textStyles.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.details, required this.onChanged});

  final GameMatchDetails details;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.matchDetailsResultLabel.toUpperCase(),
            style: context.textStyles.labelSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          if (details.hasScore)
            Text(
              '${details.goalsFor}–${details.goalsAgainst}',
              style: context.textStyles.headlineSmall,
            )
          else if (details.result != null)
            AppBadge(
              label: details.result == GameResult.win
                  ? l10n.pendingMatchWinAction
                  : l10n.pendingMatchLossAction,
              tone: details.result == GameResult.win
                  ? AppBadgeTone.success
                  : AppBadgeTone.danger,
            )
          else
            Text(
              l10n.matchDetailsNoResultMessage,
              style: context.textStyles.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          if (details.isOwner && details.isFinished) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            AppButton.secondary(
              label: l10n.matchDetailsEditResultAction,
              icon: Icons.edit_outlined,
              onPressed: () async {
                final saved = await showEditMatchResultSheet(
                  context: context,
                  matchId: details.id,
                  initialGoalsFor: details.goalsFor,
                  initialGoalsAgainst: details.goalsAgainst,
                  initialResult: details.result,
                );
                if (saved == true) {
                  onChanged();
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayerStatsCard extends StatelessWidget {
  const _PlayerStatsCard({required this.details, required this.onChanged});

  final GameMatchDetails details;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final stats = details.playerStats;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.matchDetailsPlayerStatsTitle.toUpperCase(),
            style: context.textStyles.labelSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          if (stats.isEmpty)
            Text(
              l10n.matchDetailsPlayerStatsEmptyMessage,
              style: context.textStyles.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            )
          else
            for (final stat in stats)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        stat.playerName,
                        style: context.textStyles.bodyMedium,
                      ),
                    ),
                    if (stat.goals > 0) ...<Widget>[
                      Icon(
                        Icons.sports_soccer,
                        size: AppSizing.iconSm,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        '${stat.goals}',
                        style: context.textStyles.bodyMedium,
                      ),
                      const SizedBox(width: AppSpacing.md),
                    ],
                    if (stat.assists > 0) ...<Widget>[
                      Icon(
                        Icons.assistant_navigation,
                        size: AppSizing.iconSm,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        '${stat.assists}',
                        style: context.textStyles.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
          if (details.isOwner) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            AppButton.secondary(
              label: stats.isEmpty
                  ? l10n.matchDetailsAddDetailsAction
                  : l10n.matchDetailsEditDetailsAction,
              icon: Icons.edit_outlined,
              onPressed: () async {
                final saved = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => PlayerStatsEditorPage(details: details),
                  ),
                );
                if (saved == true) {
                  onChanged();
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}
