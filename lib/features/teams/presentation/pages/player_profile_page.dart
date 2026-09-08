import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/rivals_division.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/rivals_division_l10n.dart';
import 'package:fifa_queue/features/teams/domain/entities/player_profile.dart';
import 'package:fifa_queue/features/teams/domain/repositories/team_repository.dart';
import 'package:flutter/material.dart';

/// Perfil publico de um jogador do MESMO time (Etapa 11, Parte B). Read
/// model server-side novo -- nunca mostra historico de busca, buscas
/// canceladas, outros times do usuario ou dados de outras contas.
class PlayerProfilePage extends StatefulWidget {
  const PlayerProfilePage({
    required this.teamId,
    required this.userId,
    super.key,
  });

  final String teamId;
  final String userId;

  @override
  State<PlayerProfilePage> createState() => _PlayerProfilePageState();
}

class _PlayerProfilePageState extends State<PlayerProfilePage> {
  late Future<PlayerProfile> _future;
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = getIt<TeamRepository>().fetchMemberProfile(
      teamId: widget.teamId,
      userId: widget.userId,
      fcAccountId: _selectedAccountId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: AppAppBar(title: l10n.playerProfileTitle),
      body: FutureBuilder<PlayerProfile>(
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
          final profile = snapshot.data;
          if (profile == null) {
            return const SizedBox.shrink();
          }
          return _ProfileBody(
            profile: profile,
            onSelectAccount: (accountId) => setState(() {
              _selectedAccountId = accountId;
              _load();
            }),
          );
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.profile, required this.onSelectAccount});

  final PlayerProfile profile;
  final ValueChanged<String> onSelectAccount;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.xl,
    ),
    children: <Widget>[
      _HeaderCard(profile: profile),
      const SizedBox(height: AppSpacing.lg),
      if (profile.needsAccountSelection)
        _AccountSelectionCard(
          profile: profile,
          onSelectAccount: onSelectAccount,
        )
      else ...<Widget>[
        _AccountCard(profile: profile),
        const SizedBox(height: AppSpacing.lg),
        _SquadCard(profile: profile),
        const SizedBox(height: AppSpacing.lg),
        _WeekendLeagueCard(profile: profile),
      ],
    ],
  );
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) => AppCard(
    variant: AppCardVariant.elevated,
    child: Row(
      children: <Widget>[
        AppAvatar(
          label: profile.displayName,
          imageUrl: profile.avatarUrl,
          size: AppSizing.avatarXl,
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Text(
            profile.displayName,
            style: context.textStyles.headlineSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

class _AccountSelectionCard extends StatelessWidget {
  const _AccountSelectionCard({
    required this.profile,
    required this.onSelectAccount,
  });

  final PlayerProfile profile;
  final ValueChanged<String> onSelectAccount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.playerProfileSelectAccountTitle,
            style: context.textStyles.titleSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final candidate in profile.candidateAccounts)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppButton.secondary(
                label: candidate.name,
                onPressed: () => onSelectAccount(candidate.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final account = profile.account;

    if (account == null) {
      return AppCard(
        child: AppBanner(
          tone: AppBannerTone.neutral,
          message: l10n.playerProfileNoAccountMessage,
        ),
      );
    }

    final division = RivalsDivision.tryFromKey(account.rivalsDivision);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.playerProfileAccountLabel.toUpperCase(),
            style: context.textStyles.labelSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(account.name, style: context.textStyles.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            division?.label(l10n) ?? l10n.fcAccountDivisionNone,
            style: context.textStyles.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SquadCard extends StatelessWidget {
  const _SquadCard({required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final squad = profile.squad;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.playerProfileSquadLabel.toUpperCase(),
            style: context.textStyles.labelSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (squad == null)
            Text(
              l10n.playerProfileSquadNoneMessage,
              style: context.textStyles.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            )
          else ...<Widget>[
            Text(
              '${squad.name} · ${squad.formationCode}',
              style: context.textStyles.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.playerProfileCompletenessLabel(
                squad.startingCount,
                squad.startingTotal,
              ),
              style: context.textStyles.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: AppRadii.borderSm,
              child: LinearProgressIndicator(
                value: squad.completeness,
                minHeight: 6,
                backgroundColor: colors.borderSubtle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeekendLeagueCard extends StatelessWidget {
  const _WeekendLeagueCard({required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final history = profile.weekendLeagueHistory;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.fcAccountWeekendLeagueTitle.toUpperCase(),
            style: context.textStyles.labelSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (history.isEmpty)
            Text(
              l10n.playerProfileWeekendLeagueEmptyMessage,
              style: context.textStyles.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            )
          else
            for (final entry in history)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '#${entry.number} · ${entry.season}',
                        style: context.textStyles.bodyMedium,
                      ),
                    ),
                    AppBadge(
                      label: l10n.playerProfileWeekendLeagueRecordLabel(
                        entry.wins,
                        entry.losses,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
