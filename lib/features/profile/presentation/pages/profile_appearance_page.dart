import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileAppearancePage extends StatelessWidget {
  const ProfileAppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: AppAppBar(title: l10n.settingsAppearance),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        children: <Widget>[
          AppCard(
            child: BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, mode) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _ThemeOptionTile(
                    label: l10n.themeSystem,
                    isSelected: mode == ThemeMode.system,
                    onTap: () =>
                        context.read<ThemeCubit>().select(ThemeMode.system),
                  ),
                  const AppDivider(),
                  _ThemeOptionTile(
                    label: l10n.themeLight,
                    isSelected: mode == ThemeMode.light,
                    onTap: () =>
                        context.read<ThemeCubit>().select(ThemeMode.light),
                  ),
                  const AppDivider(),
                  _ThemeOptionTile(
                    label: l10n.themeDark,
                    isSelected: mode == ThemeMode.dark,
                    onTap: () =>
                        context.read<ThemeCubit>().select(ThemeMode.dark),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: context.textStyles.bodyLarge)),
          if (isSelected)
            Icon(Icons.check, color: context.colors.textPrimary),
        ],
      ),
    ),
  );
}
