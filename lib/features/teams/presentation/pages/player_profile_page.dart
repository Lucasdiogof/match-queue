import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/rivals_division.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/rivals_division_l10n.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/squad_field.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_rank.dart';
import 'package:fifa_queue/features/game/presentation/widgets/competitive_mode_card.dart';
import 'package:fifa_queue/features/game/presentation/widgets/weekend_league_rank_l10n.dart';
import 'package:fifa_queue/features/teams/domain/entities/player_profile.dart';
import 'package:fifa_queue/features/teams/domain/repositories/team_repository.dart';
import 'package:flutter/material.dart';

/// Perfil publico de um jogador do MESMO time (Etapa 11, Parte B). Read
/// model server-side novo -- nunca mostra historico de busca, buscas
/// canceladas, outros times do usuario ou dados de outras contas.
///
/// So o essencial: foto+nome, a Conta vinculada aquele time, a escalacao
/// principal (campinho de verdade, so leitura), o historico de Champions
/// por semana (com selecao de semana) e o placar de Rivals. Sem resumo
/// esportivo -- isso saiu junto com artilharia/assistencia.
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
      else if (profile.account == null)
        const _NoAccountCard()
      else ...<Widget>[
        _SquadCard(squad: profile.squad),
        const SizedBox(height: AppSpacing.lg),
        _RivalsCard(account: profile.account!),
        const SizedBox(height: AppSpacing.lg),
        _WeekendLeagueCard(history: profile.weekendLeagueHistory),
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

class _NoAccountCard extends StatelessWidget {
  const _NoAccountCard();

  @override
  Widget build(BuildContext context) => AppCard(
    child: AppBanner(
      tone: AppBannerTone.neutral,
      message: context.l10n.playerProfileNoAccountMessage,
    ),
  );
}

/// Campinho de verdade, so leitura -- mesmo SquadField do Squad Builder,
/// sem nenhum dos callbacks fazer nada (nada de editar escalacao alheia).
class _SquadCard extends StatelessWidget {
  const _SquadCard({required this.squad});

  final PlayerProfileSquad? squad;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final squad = this.squad;

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
          else
            SquadField(
              formation: squad.formation,
              starters: squad.starters,
              onSlotTap: (_) {},
              onSlotLongPress: (_) {},
              onSlotDrop: (_, _) {},
            ),
        ],
      ),
    );
  }
}

class _RivalsCard extends StatelessWidget {
  const _RivalsCard({required this.account});

  final PlayerProfileAccount account;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final division = RivalsDivision.tryFromKey(account.rivalsDivision);

    return CompetitiveModeCard(
      mode: CompetitiveMode.rivals,
      title: l10n.rivalsSectionTitle,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              division?.label(l10n) ?? l10n.fcAccountDivisionNone,
              style: const TextStyle(
                color: AppColors.darkTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${account.rivalsWins}–${account.rivalsLosses}',
            style: const TextStyle(
              color: AppColors.darkTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

/// Historico de Champions com selecao de semana -- setas em vez de lista
/// inteira, pra caber uma semana de cada vez no mesmo card competitivo.
class _WeekendLeagueCard extends StatefulWidget {
  const _WeekendLeagueCard({required this.history});

  final List<PlayerProfileWeekendLeagueEntry> history;

  @override
  State<_WeekendLeagueCard> createState() => _WeekendLeagueCardState();
}

class _WeekendLeagueCardState extends State<_WeekendLeagueCard> {
  late int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final history = widget.history;

    if (history.isEmpty) {
      return CompetitiveModeCard(
        mode: CompetitiveMode.champions,
        title: l10n.fcAccountWeekendLeagueTitle,
        child: Text(
          l10n.playerProfileWeekendLeagueEmptyMessage,
          style: const TextStyle(color: AppColors.darkTextSecondary),
        ),
      );
    }

    final index = _index.clamp(0, history.length - 1);
    final entry = history[index];
    final rank = WeekendLeagueRank.fromWins(entry.wins);

    return CompetitiveModeCard(
      mode: CompetitiveMode.champions,
      title: l10n.fcAccountWeekendLeagueTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                onPressed: index < history.length - 1
                    ? () => setState(() => _index = index + 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
                color: AppColors.darkTextPrimary,
                disabledColor: AppColors.darkTextSecondary,
              ),
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(
                      '#${entry.number}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.darkTextPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (entry.season != null)
                      Text(
                        entry.season!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.darkTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: index > 0
                    ? () => setState(() => _index = index - 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                color: AppColors.darkTextPrimary,
                disabledColor: AppColors.darkTextSecondary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (rank != null) ...<Widget>[
            AppBadge(label: rank.label),
            const SizedBox(height: AppSpacing.sm),
          ],
          Center(
            child: Text(
              '${entry.wins}–${entry.losses}',
              style: const TextStyle(
                color: AppColors.darkTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
