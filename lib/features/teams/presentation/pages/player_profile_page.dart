import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/account/domain/entities/rivals_division.dart';
import 'package:fifa_queue/features/account/presentation/widgets/rivals_division_l10n.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/squad_field.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_history_entry.dart';
import 'package:fifa_queue/features/game/presentation/widgets/competitive_mode_card.dart';
import 'package:fifa_queue/features/game/presentation/widgets/weekend_league_history_card.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = getIt<TeamRepository>().fetchMemberProfile(
      teamId: widget.teamId,
      userId: widget.userId,
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
          return _ProfileBody(profile: profile);
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
    children: <Widget>[
      _HeaderCard(profile: profile),
      const SizedBox(height: AppSpacing.lg),
      _SquadCard(squad: profile.squad),
      const SizedBox(height: AppSpacing.lg),
      _RivalsCard(profile: profile),
      const SizedBox(height: AppSpacing.lg),
      WeekendLeagueHistoryCard(
        history: profile.weekendLeagueHistory
            .map(
              (entry) => WeekendLeagueHistoryEntry(
                eventId: entry.eventId,
                number: entry.number,
                season: entry.season,
                startsAt: entry.startsAt,
                endsAt: entry.endsAt,
                wins: entry.wins,
                losses: entry.losses,
              ),
            )
            .toList(growable: false),
      ),
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
  const _RivalsCard({required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final division = RivalsDivision.tryFromKey(profile.rivalsDivision);

    return CompetitiveModeCard(
      mode: CompetitiveMode.rivals,
      title: l10n.rivalsSectionTitle,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              division?.label(l10n) ?? l10n.rivalsDivisionNone,
              style: const TextStyle(
                color: AppColors.darkTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${profile.rivalsWins}–${profile.rivalsLosses}',
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
