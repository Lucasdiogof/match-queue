import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_squads/presentation/pages/cards_catalog_page.dart';
import 'package:fifa_queue/features/mechanics/domain/playstyle_catalog.dart';
import 'package:flutter/material.dart';

/// Detalhe de um PlayStyle: explicação (estática, autorada) + as cartas do
/// NOSSO catálogo que realmente têm esse estilo (real, via
/// [CardsCatalogView] filtrado por `playstyle`).
class PlaystyleDetailPage extends StatefulWidget {
  const PlaystyleDetailPage({required this.playstyleName, super.key});

  final String playstyleName;

  @override
  State<PlaystyleDetailPage> createState() => _PlaystyleDetailPageState();
}

class _PlaystyleDetailPageState extends State<PlaystyleDetailPage> {
  bool _plusOnly = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final info = findPlaystyleInfo(widget.playstyleName);

    return AppScaffold(
      appBar: AppAppBar(title: widget.playstyleName),
      body: AppBackground(
        dense: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (info != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppCard(
                  variant: AppCardVariant.elevated,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        playstyleCategoryLabel(info.category).toUpperCase(),
                        style: context.textStyles.labelSmall?.copyWith(
                          color: context.colors.textTertiary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.mechanicsPlaystyleEffectLabel,
                        style: context.textStyles.labelSmall,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(info.effect, style: context.textStyles.bodyMedium),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.mechanicsPlaystylePlusEffectLabel,
                        style: context.textStyles.labelSmall,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        info.plusEffect,
                        style: context.textStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  AppChip(
                    label: l10n.mechanicsPlaystyleFilterAny,
                    isSelected: !_plusOnly,
                    onPressed: () => setState(() => _plusOnly = false),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AppChip(
                    label: l10n.mechanicsPlaystyleFilterPlusOnly,
                    isSelected: _plusOnly,
                    onPressed: () => setState(() => _plusOnly = true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: CardsCatalogView(
                playstyle: widget.playstyleName,
                playstylePlusOnly: _plusOnly,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
