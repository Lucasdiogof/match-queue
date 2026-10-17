import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_manager.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/fc_squads/domain/repositories/player_card_catalog_repository.dart';
import 'package:fifa_queue/features/market/domain/repositories/market_favorites_repository.dart';
import 'package:fifa_queue/features/market/presentation/cubit/market_search_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake minimo: so o metodo usado pelo teste tem corpo real, o resto cai no
/// noSuchMethod (mesmo padrao de requests_cubit_test.dart).
class _FakeCatalogRepository implements PlayerCardCatalogRepository {
  PlayerCardPage page = const PlayerCardPage(
    items: <PlayerCard>[],
    hasMore: false,
  );
  final List<PlayerCardPage> pages = <PlayerCardPage>[];
  final List<PlayerCardQuery> queries = <PlayerCardQuery>[];

  @override
  Future<PlayerCardPage> searchCards(PlayerCardQuery query) async {
    queries.add(query);
    return pages.isEmpty ? page : pages.removeAt(0);
  }

  @override
  Future<PlayerCard?> getCard(String id) async => null;

  @override
  Future<List<FcManager>> searchManagers({
    String? nationId,
    String? query,
  }) async => <FcManager>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake de favoritos com comportamento configuravel -- registra add/remove
/// pra afirmar que o cubit chamou o repositorio certo com o id certo.
class _FakeFavoritesRepository implements MarketFavoritesRepository {
  Set<String> favoriteIds = <String>{};
  AppFailure? failureToThrow;
  final List<String> added = <String>[];
  final List<String> removed = <String>[];

  @override
  Future<List<String>> listFavoriteCardIds() async => favoriteIds.toList();

  @override
  Future<bool> isFavorite(String cardId) async => favoriteIds.contains(cardId);

  @override
  Future<void> addFavorite(String cardId) async {
    final failure = failureToThrow;
    if (failure != null) {
      throw failure;
    }
    added.add(cardId);
    favoriteIds.add(cardId);
  }

  @override
  Future<void> removeFavorite(String cardId) async {
    final failure = failureToThrow;
    if (failure != null) {
      throw failure;
    }
    removed.add(cardId);
    favoriteIds.remove(cardId);
  }
}

PlayerCard _card(String id, {String? cardType}) => PlayerCard(
  id: id,
  provider: 'TEST',
  playerName: 'Same Player',
  rating: 90,
  primaryPosition: 'ST',
  alternativePositions: const <String>[],
  cardType: cardType,
);

void main() {
  group('MarketSearchCubit pagination', () {
    test('loadMore appends the next page and keeps distinct cards of one '
        'player', () async {
      final catalog = _FakeCatalogRepository();
      final cubit = MarketSearchCubit(catalog, _FakeFavoritesRepository());
      addTearDown(cubit.close);
      catalog.pages
        ..add(
          PlayerCardPage(
            items: <PlayerCard>[_card('a'), _card('b', cardType: 'TOTW')],
            hasMore: true,
          ),
        )
        ..add(
          PlayerCardPage(
            items: <PlayerCard>[_card('b', cardType: 'TOTW'), _card('c')],
            hasMore: false,
          ),
        );

      cubit.search('same');
      await Future<void>.delayed(
        MarketSearchCubit.searchDebounce + const Duration(milliseconds: 50),
      );
      expect(cubit.state.hasMore, isTrue);

      await cubit.loadMore();

      expect(cubit.state.cards.map((card) => card.id), <String>['a', 'b', 'c']);
      expect(cubit.state.hasMore, isFalse);
      expect(catalog.queries.last.offset, MarketSearchCubit.pageLimit);
    });
  });

  group('MarketSearchCubit.toggleFavorite', () {
    late _FakeCatalogRepository catalogRepository;
    late _FakeFavoritesRepository favoritesRepository;
    late MarketSearchCubit cubit;

    setUp(() {
      catalogRepository = _FakeCatalogRepository();
      favoritesRepository = _FakeFavoritesRepository();
      cubit = MarketSearchCubit(catalogRepository, favoritesRepository);
    });

    tearDown(() => cubit.close());

    test(
      'favorita otimisticamente e chama addFavorite quando ainda nao e favorito',
      () async {
        await cubit.toggleFavorite('card-1');

        expect(cubit.state.favoriteCardIds, contains('card-1'));
        await Future<void>.delayed(Duration.zero);
        expect(favoritesRepository.added, <String>['card-1']);
      },
    );

    test(
      'desfavorita otimisticamente e chama removeFavorite quando ja e favorito',
      () async {
        favoritesRepository.favoriteIds = <String>{'card-1'};
        await cubit.loadFavoriteIds();
        expect(cubit.state.favoriteCardIds, contains('card-1'));

        await cubit.toggleFavorite('card-1');

        expect(cubit.state.favoriteCardIds, isNot(contains('card-1')));
        expect(favoritesRepository.removed, <String>['card-1']);
      },
    );

    test('reverte o icone quando o repositorio falha ao favoritar', () async {
      favoritesRepository.failureToThrow = const NetworkFailure(
        debugMessage: 'erro de teste',
      );

      await cubit.toggleFavorite('card-1');

      expect(cubit.state.favoriteCardIds, isNot(contains('card-1')));
    });
  });
}
