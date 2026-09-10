import 'dart:async';

import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_manager.dart';
import 'package:fifa_queue/features/fc_squads/domain/repositories/player_card_catalog_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Clubes do catalogo, ordenados pelo overall medio real das cartas ativas
/// -- nada de ranking fixo.
///
/// Masculino e feminino aparecem como clubes SEPARADOS, porque e isso que
/// eles sao: 42 nomes existem nos dois, e a liga (unico eixo em que a
/// separacao e limpa) e mostrada em toda linha justamente para que Arsenal
/// da Premier League e Arsenal da Barclays WSL nunca se confundam.
class ClubsCatalogPage extends StatefulWidget {
  const ClubsCatalogPage({super.key});

  @override
  State<ClubsCatalogPage> createState() => _ClubsCatalogPageState();
}

class _ClubsCatalogPageState extends State<ClubsCatalogPage> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _search = TextEditingController();

  Timer? _debounce;
  List<FcClubSummary> _clubs = <FcClubSummary>[];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  AppFailure? _failure;
  String? _gender;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    unawaited(_load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400 &&
        _hasMore &&
        !_isLoadingMore &&
        !_isLoading) {
      unawaited(_loadMore());
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _failure = null;
    });
    try {
      final page = await getIt<PlayerCardCatalogRepository>().listClubs(
        query: _search.text.trim().isEmpty ? null : _search.text.trim(),
        gender: _gender,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _clubs = page.items;
        _hasMore = page.hasMore;
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

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    try {
      final page = await getIt<PlayerCardCatalogRepository>().listClubs(
        query: _search.text.trim().isEmpty ? null : _search.text.trim(),
        gender: _gender,
        offset: _clubs.length,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _clubs = <FcClubSummary>[..._clubs, ...page.items];
        _hasMore = page.hasMore;
        _isLoadingMore = false;
      });
    } on AppFailure {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_load());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: AppAppBar(title: l10n.catalogClubsTitle),
      body: AppBackground(
        dense: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppTextField(
              label: l10n.catalogClubsSearchLabel,
              hintText: l10n.catalogClubsSearchHint,
              controller: _search,
              prefixIcon: Icons.search,
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  AppChip(
                    // "Todos" e nao "Todas": clube e masculino em PT/ES, e a
                    // chave compartilhada com cartas concordava errado aqui.
                    label: l10n.catalogClubsFilterAll,
                    isSelected: _gender == null,
                    onPressed: () {
                      setState(() => _gender = null);
                      unawaited(_load());
                    },
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AppChip(
                    label: l10n.catalogGenderMen,
                    isSelected: _gender == 'MALE',
                    onPressed: () {
                      setState(() => _gender = 'MALE');
                      unawaited(_load());
                    },
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AppChip(
                    label: l10n.catalogGenderWomen,
                    isSelected: _gender == 'FEMALE',
                    onPressed: () {
                      setState(() => _gender = 'FEMALE');
                      unawaited(_load());
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(child: _body(context)),
          ],
        ),
      ),
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
    if (_clubs.isEmpty) {
      return AppEmptyState(
        icon: Icons.shield_outlined,
        title: l10n.catalogClubsEmptyTitle,
        message: l10n.catalogClubsEmptyMessage,
      );
    }

    return ListView.separated(
      controller: _scroll,
      itemCount: _clubs.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index >= _clubs.length) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: AppLoading.inline(),
          );
        }
        return _ClubRow(club: _clubs[index]);
      },
    );
  }
}

class _ClubRow extends StatelessWidget {
  const _ClubRow({required this.club});

  final FcClubSummary club;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return AppCard(
      onTap: () => context.push(AppRoutes.clubDetailLocation(club.clubId)),
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
            // Escudo so quando existe dado real -- o pacote FC27 nao trouxe
            // nenhum, entao hoje isto e sempre a inicial.
            child: club.logoImageUrl == null
                ? Text(
                    club.name.isEmpty ? '?' : club.name[0].toUpperCase(),
                    style: context.textStyles.titleSmall,
                  )
                : Image.network(
                    club.logoImageUrl!,
                    width: AppSizing.iconXl,
                    height: AppSizing.iconXl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Text(
                      club.name.isEmpty ? '?' : club.name[0].toUpperCase(),
                      style: context.textStyles.titleSmall,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  club.name,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  // Genero explicito em toda linha, nao so nos homonimos:
                  // saber que "Barclays WSL" e feminina nao pode ser
                  // pre-requisito pra ler a lista.
                  <String>[
                    if (club.leagueName != null) club.leagueName!,
                    if (club.gender != null)
                      club.gender == 'FEMALE'
                          ? l10n.catalogGenderWomen
                          : l10n.catalogGenderMen,
                    l10n.catalogClubCardsCount(club.cardCount),
                  ].join(' · '),
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (club.averageRating != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  '${club.averageRating}',
                  style: context.textStyles.titleMedium,
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
      ),
    );
  }
}
