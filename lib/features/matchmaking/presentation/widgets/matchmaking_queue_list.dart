import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/matchmaking_snapshot.dart';
import 'package:flutter/material.dart';

class MatchmakingQueueList extends StatelessWidget {
  const MatchmakingQueueList({required this.queue, this.myPosition, super.key});

  final List<MatchmakingQueueEntry> queue;
  final int? myPosition;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (queue.isEmpty) {
      return Text(
        l10n.matchmakingQueueEmptyMessage,
        style: context.textStyles.bodySmall,
      );
    }

    return Column(
      children: <Widget>[
        for (final entry in queue) ...<Widget>[
          _QueueRow(entry: entry, isMe: entry.position == myPosition),
          if (entry != queue.last) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.entry, required this.isMe});

  final MatchmakingQueueEntry entry;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return Row(
      children: <Widget>[
        SizedBox(
          width: 24,
          child: Text(
            '${entry.position}',
            textAlign: TextAlign.center,
            style: context.textStyles.labelLarge?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppAvatar(
          label: entry.displayName,
          imageUrl: entry.avatarUrl,
          size: AppSizing.avatarSm,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            entry.displayName,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.bodyMedium?.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ),
        if (isMe) ...<Widget>[
          const SizedBox(width: AppSpacing.sm),
          AppBadge(label: l10n.matchmakingYouBadge, tone: AppBadgeTone.info),
        ],
      ],
    );
  }
}
