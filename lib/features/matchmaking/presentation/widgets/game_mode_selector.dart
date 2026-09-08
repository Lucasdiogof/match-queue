import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';
import 'package:fifa_queue/features/matchmaking/presentation/cubit/game_mode_cubit.dart';
import 'package:fifa_queue/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GameModeSelector extends StatelessWidget {
  const GameModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<GameModeCubit, GameMode>(
      builder: (context, selected) => Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: <Widget>[
          for (final mode in GameMode.values)
            AppChip(
              label: mode.label(l10n),
              icon: mode.icon,
              isSelected: mode == selected,
              onPressed: () => context.read<GameModeCubit>().select(mode),
            ),
        ],
      ),
    );
  }
}

extension GameModeL10n on GameMode {
  String label(AppLocalizations l10n) => switch (this) {
    GameMode.weekendLeague => l10n.gameModeWeekendLeague,
    GameMode.divisionRivals => l10n.gameModeDivisionRivals,
  };

  IconData get icon => switch (this) {
    GameMode.weekendLeague => Icons.emoji_events_outlined,
    GameMode.divisionRivals => Icons.shield_outlined,
  };
}
