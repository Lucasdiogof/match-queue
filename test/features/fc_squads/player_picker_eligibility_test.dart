import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/fc_squads/domain/repositories/player_card_catalog_repository.dart';
import 'package:fifa_queue/features/fc_squads/presentation/cubit/player_picker_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

PlayerCard _card(
  String name,
  String primary,
  List<String> alternatives, {
  int rating = 80,
}) => PlayerCard(
  id: name,
  provider: 'TEST',
  playerName: name,
  rating: rating,
  primaryPosition: primary,
  alternativePositions: alternatives,
);

/// Devolve sempre a mesma pagina (ja "paginada" pelo chamador do teste),
/// como o servidor faz: rating desc, sem filtrar por posicao quando
/// [PlayerCardQuery.position] vem nulo.
class _FakeCatalogRepository implements PlayerCardCatalogRepository {
  _FakeCatalogRepository(this.cards);

  final List<PlayerCard> cards;

  @override
  Future<PlayerCardPage> searchCards(PlayerCardQuery query) async {
    final filtered =
        cards
            .where(
              (c) => query.position == null || c.canPlayIn(query.position!),
            )
            .toList()
          ..sort((a, b) => b.rating.compareTo(a.rating));
    final end = (query.offset + query.limit).clamp(0, filtered.length);
    return PlayerCardPage(
      items: filtered.sublist(query.offset.clamp(0, filtered.length), end),
      hasMore: end < filtered.length,
    );
  }

  @override
  Never noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

void main() {
  group('eligibilityTier', () {
    test('posicao principal vem primeiro', () {
      expect(eligibilityTier(_card('a', 'LB', const <String>[]), 'LB'), 0);
    });

    test('alternativa declarada e elegivel', () {
      expect(eligibilityTier(_card('a', 'CB', const <String>['LB']), 'LB'), 1);
    });

    test('sem relacao declarada NAO e elegivel, mesmo sendo defensor', () {
      // A regra e posicao principal + alternativas reais da carta. Nada de
      // "LB aceita qualquer defensor" -- um zagueiro central sem LB entre as
      // alternativas nao joga ali.
      expect(eligibilityTier(_card('a', 'CB', const <String>[]), 'LB'), 2);
    });

    test('atacante nunca e sugestao de lateral', () {
      expect(eligibilityTier(_card('a', 'ST', const <String>['CF']), 'LB'), 2);
    });

    test('goleiro so e elegivel em GK', () {
      final gk = _card('a', 'GK', const <String>[]);
      expect(eligibilityTier(gk, 'GK'), 0);
      expect(eligibilityTier(gk, 'CB'), 2);
    });

    test('jogador de linha nao entra no gol', () {
      expect(eligibilityTier(_card('a', 'CB', const <String>[]), 'GK'), 2);
    });
  });

  group('PlayerPickerCubit sem "Compatíveis"', () {
    test('nunca esconde quem nao joga ali (item 43), so ordena', () async {
      // Reproduz o bug achado ao vivo: um catalogo onde os GK sao os
      // ratings mais baixos nunca aparecia na primeira pagina, porque a
      // RPC ordena por rating (sem filtrar posicao quando o toggle esta
      // desligado) e o client filtrava por elegibilidade em cima da
      // pagina ja cortada -- a pagina inteira ficava vazia em vez de so
      // reordenada.
      final cards = <PlayerCard>[
        _card('st1', 'ST', const <String>[], rating: 90),
        _card('st2', 'ST', const <String>[], rating: 89),
        _card('gk1', 'GK', const <String>[], rating: 70),
      ];
      final cubit = PlayerPickerCubit(
        _FakeCatalogRepository(cards),
        positionCode: 'GK',
      );
      addTearDown(cubit.close);

      await cubit.load();

      // Nada some: os 3 seguem visiveis, so o elegivel (GK) sobe pro
      // topo em vez de ficar escondido atras dos outros.
      expect(cubit.state.cards.map((c) => c.id), <String>['gk1', 'st1', 'st2']);
    });

    test('"Compatíveis" ligado filtra de verdade', () async {
      final cards = <PlayerCard>[
        _card('st1', 'ST', const <String>[], rating: 90),
        _card('gk1', 'GK', const <String>[], rating: 70),
      ];
      final cubit = PlayerPickerCubit(
        _FakeCatalogRepository(cards),
        positionCode: 'GK',
      );
      addTearDown(cubit.close);

      cubit.setCompatibleOnly(true);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.cards.map((c) => c.id), <String>['gk1']);
    });
  });
}
