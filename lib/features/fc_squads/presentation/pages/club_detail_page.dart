import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_manager.dart';
import 'package:fifa_queue/features/fc_squads/domain/repositories/player_card_catalog_repository.dart';
import 'package:fifa_queue/features/fc_squads/presentation/pages/cards_catalog_page.dart';
import 'package:flutter/material.dart';

/// Resumo do clube + suas cartas. O corpo e a [CardsCatalogView] presa a
/// este clube por id -- busca, filtros e paginacao ja resolvidos la, sem uma
/// segunda implementacao para manter em sincronia.
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

    // O Scaffold e a AppBar sao SEMPRE desta pagina, em todos os estados:
    // antes, o sucesso devolvia uma Column solta com uma pagina inteira
    // dentro, o que empilhava duas barras e escondia o botao voltar.
    return FutureBuilder<FcClubSummary>(
      future: _summary,
      builder: (context, snapshot) {
        final club = snapshot.data;
        return AppScaffold(
          appBar: AppAppBar(title: club?.name ?? l10n.catalogClubsTitle),
          body: AppBackground(
            dense: true,
            child: _content(context, snapshot, club),
          ),
        );
      },
    );
  }

  Widget _content(
    BuildContext context,
    AsyncSnapshot<FcClubSummary> snapshot,
    FcClubSummary? club,
  ) {
    final l10n = context.l10n;

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
    if (club == null) {
      return AppEmptyState(
        icon: Icons.shield_outlined,
        title: l10n.catalogClubsEmptyTitle,
        message: l10n.catalogClubsEmptyMessage,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ClubHeader(club: club),
        const SizedBox(height: AppSpacing.lg),
        Expanded(child: CardsCatalogView(clubId: widget.clubId)),
      ],
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

    return AppCard(
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
                    if (club.gender != null)
                      club.gender == 'FEMALE'
                          ? l10n.catalogGenderWomen
                          : l10n.catalogGenderMen,
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
    );
  }
}
