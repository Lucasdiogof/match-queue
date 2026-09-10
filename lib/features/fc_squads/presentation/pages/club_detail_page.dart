import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_manager.dart';
import 'package:fifa_queue/features/fc_squads/domain/repositories/player_card_catalog_repository.dart';
import 'package:fifa_queue/features/fc_squads/presentation/pages/cards_catalog_page.dart';
import 'package:flutter/material.dart';

/// Resumo do clube + suas cartas. O corpo e a propria [CardsCatalogPage]
/// presa a este clube por id -- busca, filtros e paginacao ja resolvidos ali,
/// sem uma segunda implementacao para manter em sincronia.
class ClubDetailPage extends StatefulWidget {
  const ClubDetailPage({required this.clubId, super.key});

  final String clubId;

  @override
  State<ClubDetailPage> createState() => _ClubDetailPageState();
}

class _ClubDetailPageState extends State<ClubDetailPage> {
  late Future<FcClubSummary> _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _summary = getIt<PlayerCardCatalogRepository>().getClubSummary(
      widget.clubId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FutureBuilder<FcClubSummary>(
      future: _summary,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AppScaffold(appBar: AppAppBar(), body: AppLoading());
        }
        final error = snapshot.error;
        if (error != null) {
          return AppScaffold(
            appBar: const AppAppBar(),
            body: AppErrorState(
              title: l10n.errorUnexpected,
              message: error is AppFailure
                  ? error.localizedMessage(l10n)
                  : l10n.errorUnexpected,
              retryLabel: l10n.actionRetry,
              onRetry: () => setState(_load),
            ),
          );
        }
        final club = snapshot.data;
        if (club == null) {
          return const AppScaffold(
            appBar: AppAppBar(),
            body: SizedBox.shrink(),
          );
        }

        return Column(
          children: <Widget>[
            _ClubHeader(club: club),
            Expanded(
              child: CardsCatalogPage(clubId: widget.clubId, title: club.name),
            ),
          ],
        );
      },
    );
  }
}

class _ClubHeader extends StatelessWidget {
  const _ClubHeader({required this.club});

  final FcClubSummary club;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return Material(
      color: colors.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: AppCard(
            variant: AppCardVariant.elevated,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(club.name, style: context.textStyles.titleMedium),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        <String>[
                          if (club.leagueName != null) club.leagueName!,
                          l10n.catalogClubCardsCount(club.cardCount),
                        ].join(' · '),
                        style: context.textStyles.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (club.averageRating != null) ...<Widget>[
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        '${club.averageRating}',
                        style: context.textStyles.headlineSmall,
                      ),
                      Text(
                        l10n.catalogClubAverageLabel,
                        style: context.textStyles.labelSmall?.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
