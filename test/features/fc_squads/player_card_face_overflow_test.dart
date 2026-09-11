import 'package:fifa_queue/core/design_system/theme/app_theme.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/player_card_face.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// O bug original era "A RenderFlex overflowed by 0.403 pixels on the right"
/// na faixa de atributos. Nao era culpa de um jogador especifico: bastava
/// valor + rotulo passarem da largura da coluna, o que muda com a escala de
/// fonte do aparelho e com a largura da carta.
///
/// Estes testes reprovam se o overflow voltar, incluindo fracao de pixel --
/// qualquer RenderFlex estourado vira excecao no `flutter_test`.
PlayerCard _card({
  required String name,
  required int rating,
  String position = 'CB',
  int? stat = 85,
}) => PlayerCard(
  id: 'card-1',
  provider: 'TEST',
  playerName: name,
  rating: rating,
  primaryPosition: position,
  alternativePositions: const <String>[],
  clubName: 'Clube com um nome bastante longo',
  nationName: 'Pais com nome longo tambem',
  pace: stat,
  shooting: stat,
  passing: stat,
  dribbling: stat,
  defending: stat,
  physical: stat,
);

Future<void> _pump(
  WidgetTester tester,
  PlayerCard card, {
  required double width,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: Center(
            child: SizedBox(width: width, child: PlayerCardFace(card: card)),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('PlayerCardFace nao estoura', () {
    testWidgets('na largura real da grade do catalogo', (tester) async {
      await _pump(tester, _card(name: 'Tom Davies', rating: 75), width: 158);
      expect(tester.takeException(), isNull);
    });

    testWidgets('numa carta bem estreita', (tester) async {
      await _pump(tester, _card(name: 'Tom Davies', rating: 75), width: 96);
      expect(tester.takeException(), isNull);
    });

    testWidgets('com atributos de tres digitos', (tester) async {
      await _pump(
        tester,
        _card(name: 'Tom Davies', rating: 99, stat: 100),
        width: 110,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('com nome e posicao longos', (tester) async {
      await _pump(
        tester,
        _card(
          name: 'Jogador Com Nome Absurdamente Longo Da Silva Junior',
          rating: 88,
          position: 'CDM',
        ),
        width: 120,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('com escala de fonte grande do aparelho', (tester) async {
      await _pump(
        tester,
        _card(name: 'Tom Davies', rating: 75, stat: 100),
        width: 158,
        textScale: 1.6,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('sem nenhum atributo preenchido', (tester) async {
      await _pump(
        tester,
        _card(name: 'Tom Davies', rating: 75, stat: null),
        width: 96,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
