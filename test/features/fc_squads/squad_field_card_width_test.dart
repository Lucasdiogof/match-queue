import 'package:fifa_queue/features/fc_squads/domain/entities/formation.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/squad_field.dart';
import 'package:flutter_test/flutter_test.dart';

FormationSlot _slot(String code, double x, double y) =>
    FormationSlot(slotCode: code, positionCode: 'CB', x: x, y: y, sortOrder: 0);

void main() {
  group('cardWidthForFormation', () {
    test('falls back to the fixed baseline with no shared rows', () {
      final slots = <FormationSlot>[
        _slot('GK', 0.5, 0.05),
        _slot('ST', 0.5, 0.90),
      ];
      const width = 380.0;
      expect(
        cardWidthForFormation(slots, width),
        (width / 5.4).clamp(48.0, 96.0),
      );
    });

    test('shrinks below baseline for a dense 5-across back line', () {
      // Mesma disposicao do 5-2-1-2 que causava overlap real: 5 slots na
      // mesma linha, espacados a 0.20 de usableW.
      final backLine = <FormationSlot>[
        _slot('LWB', 0.10, 0.20),
        _slot('LCB', 0.30, 0.20),
        _slot('CB', 0.50, 0.20),
        _slot('RCB', 0.70, 0.20),
        _slot('RWB', 0.90, 0.20),
      ];
      const width = 380.0;
      final baseline = (width / 5.4).clamp(48.0, 96.0);
      final result = cardWidthForFormation(backLine, width);

      expect(result, lessThan(baseline));
      // Nunca menor que o minimo absoluto, mesmo numa linha muito densa.
      expect(result, greaterThanOrEqualTo(48.0));
    });

    test('respects the row spacing when it lands above the size floor', () {
      final tightRow = <FormationSlot>[
        _slot('A', 0.40, 0.5),
        _slot('B', 0.60, 0.5),
      ];
      const width = 380.0;
      final result = cardWidthForFormation(tightRow, width);
      const gapPixels = 0.20 * width * 0.9;

      expect(result, lessThanOrEqualTo(gapPixels));
      expect(result, greaterThanOrEqualTo(48.0));
    });

    test(
      'never shrinks below the absolute minimum even under extreme density',
      () {
        final extremelyTightRow = <FormationSlot>[
          _slot('A', 0.49, 0.5),
          _slot('B', 0.51, 0.5),
        ];
        const width = 380.0;
        expect(cardWidthForFormation(extremelyTightRow, width), 48.0);
      },
    );

    test('is stable across repeated calls with the same formation', () {
      final slots = <FormationSlot>[
        _slot('LB', 0.15, 0.25),
        _slot('CB1', 0.38, 0.25),
        _slot('CB2', 0.62, 0.25),
        _slot('RB', 0.85, 0.25),
      ];
      const width = 400.0;
      final first = cardWidthForFormation(slots, width);
      final second = cardWidthForFormation(slots, width);
      expect(first, second);
    });
  });
}
