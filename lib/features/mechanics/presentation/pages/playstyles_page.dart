import 'dart:async';

import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/fc_squads/domain/repositories/player_card_catalog_repository.dart';
import 'package:fifa_queue/features/mechanics/domain/playstyle_catalog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Lista de PlayStyles: catálogo (nome/categoria) é conteúdo estático
/// autorado -- não muda carta a carta -- mas a contagem "X cartas com este
/// estilo" vem de `get_fc_playstyle_summary`, sempre real.
class PlaystylesPage extends StatefulWidget {
  const PlaystylesPage({super.key});

  @override
  State<PlaystylesPage> createState() => _PlaystylesPageState();
}

class _PlaystylesPageState extends State<PlaystylesPage> {
  bool _isLoading = true;
  AppFailure? _failure;
  Map<String, FcPlaystyleSummary> _summaryByStyle =
      <String, FcPlaystyleSummary>{};

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _failure = null;
    });
    try {
      final summary = await getIt<PlayerCardCatalogRepository>()
          .getPlaystyleSummary();
      if (!mounted) {
        return;
      }
      setState(() {
        _summaryByStyle = <String, FcPlaystyleSummary>{
          for (final entry in summary) entry.style: entry,
        };
        _isLoading = false;
      });
    } on AppFailure catch (failure) {
      if (mounted) {
        setState(() {
          _failure = failure;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: AppAppBar(title: l10n.mechanicsPlaystylesLabel),
      body: AppBackground(dense: true, child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    final l10n = context.l10n;

    if (_isLoading) {
      return const AppLoading();
    }
    final failure = _failure;
    if (failure != null) {
      return AppErrorState(
        title: l10n.errorUnexpected,
        message: failure.localizedMessage(l10n),
        retryLabel: l10n.actionRetry,
        onRetry: () => unawaited(_load()),
      );
    }

    final byCategory = <PlaystyleCategory, List<PlaystyleInfo>>{};
    for (final info in kPlaystyleCatalog) {
      (byCategory[info.category] ??= <PlaystyleInfo>[]).add(info);
    }

    return ListView(
      children: <Widget>[
        for (final category in PlaystyleCategory.values)
          if (byCategory[category] case final infos?) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                playstyleCategoryLabel(category).toUpperCase(),
                style: context.textStyles.labelSmall?.copyWith(
                  color: context.colors.textTertiary,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            for (final info in infos)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _PlaystyleRow(
                  info: info,
                  summary: _summaryByStyle[info.name],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }
}

class _PlaystyleRow extends StatelessWidget {
  const _PlaystyleRow({required this.info, required this.summary});

  final PlaystyleInfo info;
  final FcPlaystyleSummary? summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final totalCards =
        (summary?.cardCount ?? 0) + (summary?.plusCardCount ?? 0);

    return AppCard(
      onTap: () => context.push(AppRoutes.playstyleDetailLocation(info.name)),
      child: Row(
        children: <Widget>[
          Container(
            width: AppSizing.iconXl,
            height: AppSizing.iconXl,
            decoration: BoxDecoration(
              color: colors.surfaceHighest,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.auto_awesome_outlined, color: colors.textPrimary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(info.name, style: context.textStyles.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  l10n.mechanicsPlaystylesCardCount(totalCards),
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colors.textTertiary),
        ],
      ),
    );
  }
}
