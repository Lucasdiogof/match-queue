import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/teams/domain/entities/team.dart';
import 'package:fifa_queue/features/teams/domain/repositories/team_repository.dart';
import 'package:flutter/material.dart';

/// Pagina publica de um time (aba Explorar). `found = false` cobre tanto
/// "nao existe" quanto "e privado" -- get_public_team nunca revela a
/// diferenca (mesma postura de PublicProfilePage).
class TeamPublicPage extends StatefulWidget {
  const TeamPublicPage({required this.teamId, super.key});

  final String teamId;

  @override
  State<TeamPublicPage> createState() => _TeamPublicPageState();
}

class _TeamPublicPageState extends State<TeamPublicPage> {
  late Future<PublicTeam> _future;

  @override
  void initState() {
    super.initState();
    _future = getIt<TeamRepository>().getPublicTeam(widget.teamId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: const AppAppBar(),
      body: AppBackground(
        dense: true,
        child: FutureBuilder<PublicTeam>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const AppLoading();
            }
            final team = snapshot.data!;
            if (!team.found) {
              return AppErrorState(
                title: l10n.teamPublicPageNotFoundTitle,
                message: l10n.teamPublicPageNotFoundMessage,
              );
            }
            return _TeamPublicBody(team: team);
          },
        ),
      ),
    );
  }
}

class _TeamPublicBody extends StatelessWidget {
  const _TeamPublicBody({required this.team});

  final PublicTeam team;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final record = team.record;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      children: <Widget>[
        Center(
          child: Column(
            children: <Widget>[
              CircleAvatar(
                radius: AppSizing.avatarLg,
                backgroundColor: colors.surfaceHighest,
                backgroundImage: team.logoUrl != null
                    ? NetworkImage(team.logoUrl!)
                    : null,
                child: team.logoUrl == null
                    ? Text(
                        team.name?.substring(0, 1).toUpperCase() ?? '?',
                        style: context.textStyles.titleLarge,
                      )
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(team.name ?? '', style: context.textStyles.headlineSmall),
              if (team.tag != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xxs),
                AppBadge(label: team.tag!),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (record != null) ...<Widget>[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.teamPublicPageRecordTitle.toUpperCase(),
                  style: context.textStyles.labelSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.teamPublicPageRecordLine(record.wins, record.losses),
                  style: context.textStyles.titleMedium,
                ),
                Text(
                  '${record.goalsFor}-${record.goalsAgainst}',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.teamPublicPageMembersTitle.toUpperCase(),
                style: context.textStyles.labelSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.teamMembersCount(team.memberCount),
                style: context.textStyles.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              if (team.members.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                for (final member in team.members)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: <Widget>[
                        AppAvatar(
                          label: member.displayName,
                          imageUrl: member.avatarUrl,
                          size: AppSizing.avatarSm,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            member.displayName,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
