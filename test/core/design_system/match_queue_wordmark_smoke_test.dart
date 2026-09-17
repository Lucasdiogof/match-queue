import 'package:fifa_queue/core/design_system/branding/match_queue_wordmark.dart';
import 'package:fifa_queue/core/design_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, ThemeData theme) => tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: const Scaffold(
        body: Center(child: MatchQueueWordmark(animate: false)),
      ),
    ),
  );

  // pumpAndSettle() nao serve aqui: os tres pontinhos de _QueueDotsIndicator
  // giram num loop DE PROPOSITO permanente (repeat()), entao a animacao
  // nunca "assenta" -- pumpAndSettle esperaria pra sempre e estouraria por
  // timeout. Uns pumps com duracao fixa bastam pra cruzar o ciclo inteiro
  // (2s) e confirmar que nada quebra em nenhuma fase dele.
  Future<void> pumpThroughOneCycle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('renderiza sem excecao no tema escuro', (tester) async {
    await pump(tester, AppTheme.dark);
    await pumpThroughOneCycle(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(MatchQueueWordmark), findsOneWidget);
  });

  testWidgets('renderiza sem excecao no tema claro', (tester) async {
    await pump(tester, AppTheme.light);
    await pumpThroughOneCycle(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renderiza sem excecao em altura pequena (celular estreito)', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(300, 500));
    await pump(tester, AppTheme.dark);
    await pumpThroughOneCycle(tester);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });
}
