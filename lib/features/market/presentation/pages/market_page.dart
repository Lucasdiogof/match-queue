import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_squads/domain/repositories/player_card_catalog_repository.dart';
import 'package:fifa_queue/features/market/domain/repositories/market_favorites_repository.dart';
import 'package:fifa_queue/features/market/presentation/cubit/market_favorites_cubit.dart';
import 'package:fifa_queue/features/market/presentation/cubit/market_search_cubit.dart';
import 'package:fifa_queue/features/market/presentation/widgets/market_favorites_tab.dart';
import 'package:fifa_queue/features/market/presentation/widgets/market_search_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Mercado: consulta de preco de carta (aba Mercado, busca explicita, nunca
/// lista nada por padrao) + watchlist pessoal (aba Favoritos). Nunca compra
/// nem vende nada -- so consulta e monitora. Mesmo padrao de duas abas de
/// Times (Meus Times/Explorar).
class MarketPage extends StatelessWidget {
  const MarketPage({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: <BlocProvider<dynamic>>[
      BlocProvider<MarketSearchCubit>(
        create: (_) =>
            MarketSearchCubit(
              getIt<PlayerCardCatalogRepository>(),
              getIt<MarketFavoritesRepository>(),
            )..loadFavoriteIds(),
      ),
      BlocProvider<MarketFavoritesCubit>(
        create: (_) =>
            MarketFavoritesCubit(
              getIt<MarketFavoritesRepository>(),
              getIt<PlayerCardCatalogRepository>(),
            )..load(),
      ),
    ],
    child: const _MarketView(),
  );
}

class _MarketView extends StatefulWidget {
  const _MarketView();

  @override
  State<_MarketView> createState() => _MarketViewState();
}

class _MarketViewState extends State<_MarketView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: AppAppBar(title: l10n.marketTitle),
      body: AppBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TabBar(
              controller: _tabController,
              tabs: <Widget>[
                Tab(text: l10n.marketTabMarket),
                Tab(text: l10n.marketTabFavorites),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const <Widget>[
                  MarketSearchTab(),
                  MarketFavoritesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
