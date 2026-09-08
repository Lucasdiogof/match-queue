import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_locales.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/settings/presentation/cubit/locale_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileLanguagePage extends StatelessWidget {
  const ProfileLanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: AppAppBar(title: l10n.settingsLanguage),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        children: <Widget>[
          AppCard(
            child: BlocBuilder<LocaleCubit, Locale?>(
              builder: (context, locale) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _LanguageOptionTile(
                    label: l10n.languageSystem,
                    isSelected: locale == null,
                    onTap: () => context.read<LocaleCubit>().select(null),
                  ),
                  const AppDivider(),
                  _LanguageOptionTile(
                    label: l10n.languagePortuguese,
                    isSelected: locale == AppLocales.portuguese,
                    onTap: () => context.read<LocaleCubit>().select(
                      AppLocales.portuguese,
                    ),
                  ),
                  const AppDivider(),
                  _LanguageOptionTile(
                    label: l10n.languageEnglish,
                    isSelected: locale == AppLocales.english,
                    onTap: () =>
                        context.read<LocaleCubit>().select(AppLocales.english),
                  ),
                  const AppDivider(),
                  _LanguageOptionTile(
                    label: l10n.languageSpanish,
                    isSelected: locale == AppLocales.spanish,
                    onTap: () =>
                        context.read<LocaleCubit>().select(AppLocales.spanish),
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

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
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
          if (isSelected) Icon(Icons.check, color: context.colors.textPrimary),
        ],
      ),
    ),
  );
}
