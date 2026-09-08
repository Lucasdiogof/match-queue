import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/game/domain/entities/game_match_details.dart';
import 'package:fifa_queue/features/game/domain/repositories/game_repository.dart';
import 'package:flutter/material.dart';

/// Editor em lote de gols/assistencias de uma partida. Jogadores vem
/// EXCLUSIVAMENTE do squad_snapshot congelado da partida (nunca do squad
/// atual, que pode ja ter mudado) -- titulares e banco, ambos elegiveis.
/// "Salvar detalhes" e explicito, sem autosave: e uma operacao em lote.
class PlayerStatsEditorPage extends StatefulWidget {
  const PlayerStatsEditorPage({required this.details, super.key});

  final GameMatchDetails details;

  @override
  State<PlayerStatsEditorPage> createState() => _PlayerStatsEditorPageState();
}

class _PlayerStatsEditorPageState extends State<PlayerStatsEditorPage> {
  final Map<String, int> _goals = <String, int>{};
  final Map<String, int> _assists = <String, int>{};
  bool _isSaving = false;
  AppFailure? _failure;

  SquadSnapshot get _snapshot => widget.details.squadSnapshot!;

  @override
  void initState() {
    super.initState();
    for (final player in _snapshot.players) {
      _goals[player.cardId] = 0;
      _assists[player.cardId] = 0;
    }
    for (final stat in widget.details.playerStats) {
      _goals[stat.snapshotPlayerKey] = stat.goals;
      _assists[stat.snapshotPlayerKey] = stat.assists;
    }
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _failure = null;
    });
    final stats = <GameMatchPlayerStatInput>[
      for (final player in _snapshot.players)
        GameMatchPlayerStatInput(
          snapshotPlayerKey: player.cardId,
          goals: _goals[player.cardId] ?? 0,
          assists: _assists[player.cardId] ?? 0,
        ),
    ];
    try {
      await getIt<GameRepository>().upsertPlayerStats(
        matchId: widget.details.id,
        stats: stats,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on AppFailure catch (failure) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _failure = failure;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final starting = _snapshot.startingPlayers;
    final bench = _snapshot.benchPlayers;

    return AppScaffold(
      appBar: AppAppBar(title: l10n.playerStatsEditorTitle),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        children: <Widget>[
          if (_failure != null) ...<Widget>[
            AppBanner(
              tone: AppBannerTone.danger,
              message: _failure!.localizedMessage(l10n),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (starting.isNotEmpty) ...<Widget>[
            Text(
              l10n.playerStatsEditorStartingLabel.toUpperCase(),
              style: context.textStyles.labelSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final player in starting)
              _PlayerStatRow(
                player: player,
                goals: _goals[player.cardId] ?? 0,
                assists: _assists[player.cardId] ?? 0,
                onGoalsChanged: (value) =>
                    setState(() => _goals[player.cardId] = value),
                onAssistsChanged: (value) =>
                    setState(() => _assists[player.cardId] = value),
              ),
          ],
          if (bench.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.playerStatsEditorBenchLabel.toUpperCase(),
              style: context.textStyles.labelSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final player in bench)
              _PlayerStatRow(
                player: player,
                goals: _goals[player.cardId] ?? 0,
                assists: _assists[player.cardId] ?? 0,
                onGoalsChanged: (value) =>
                    setState(() => _goals[player.cardId] = value),
                onAssistsChanged: (value) =>
                    setState(() => _assists[player.cardId] = value),
              ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: l10n.playerStatsEditorSaveAction,
            isLoading: _isSaving,
            expanded: true,
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _PlayerStatRow extends StatelessWidget {
  const _PlayerStatRow({
    required this.player,
    required this.goals,
    required this.assists,
    required this.onGoalsChanged,
    required this.onAssistsChanged,
  });

  final SquadSnapshotPlayer player;
  final int goals;
  final int assists;
  final ValueChanged<int> onGoalsChanged;
  final ValueChanged<int> onAssistsChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            player.position == null
                ? player.playerName
                : '${player.playerName} · ${player.position}',
            style: context.textStyles.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: <Widget>[
              Expanded(
                child: _Stepper(
                  icon: Icons.sports_soccer,
                  label: l10n.statsGoalsLabel,
                  value: goals,
                  onChanged: onGoalsChanged,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _Stepper(
                  icon: Icons.assistant_navigation,
                  label: l10n.statsAssistsLabel,
                  value: assists,
                  onChanged: onAssistsChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(color: colors.borderSubtle, height: 1),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  static const int _max = 99;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: <Widget>[
        Icon(icon, size: AppSizing.iconSm, color: colors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(label, style: context.textStyles.labelSmall)),
        AppIconButton(
          icon: Icons.remove_circle_outline,
          tooltip: '-',
          variant: AppIconButtonVariant.surface,
          size: AppSizing.iconButtonSize * 0.8,
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: context.textStyles.titleSmall,
          ),
        ),
        AppIconButton(
          icon: Icons.add_circle_outline,
          tooltip: '+',
          variant: AppIconButtonVariant.surface,
          size: AppSizing.iconButtonSize * 0.8,
          onPressed: value < _max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}
