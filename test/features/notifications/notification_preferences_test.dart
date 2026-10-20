import 'package:fifa_queue/features/notifications/domain/entities/notification_category.dart';
import 'package:fifa_queue/features/notifications/domain/entities/notification_preferences.dart';
import 'package:fifa_queue/features/notifications/domain/entities/push_notification_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('padrão', () {
    test('ausência de linha no backend significa tudo ligado', () {
      const p = NotificationPreferences.enabled;
      for (final t in PushNotificationType.values) {
        expect(p.isEnabled(t), isTrue, reason: t.name);
      }
      for (final c in NotificationCategory.values) {
        expect(p.isCategoryEnabled(c), isTrue, reason: c.name);
      }
      expect(p, const NotificationPreferences());
    });
  });

  group('isEnabled (push de matchmaking)', () {
    test('o interruptor da categoria manda sobre os três granulares', () {
      final off = const NotificationPreferences().copyWithCategory(
        NotificationCategory.matchmaking,
        false,
      );
      for (final t in PushNotificationType.values) {
        expect(off.isEnabled(t), isFalse, reason: t.name);
      }
    });

    test('desligar um tipo não afeta os outros', () {
      final p = const NotificationPreferences().copyWithType(
        PushNotificationType.searchExpiring,
        false,
      );
      expect(p.isEnabled(PushNotificationType.searchExpiring), isFalse);
      expect(p.isEnabled(PushNotificationType.yourTurn), isTrue);
      expect(p.isEnabled(PushNotificationType.searchExpired), isTrue);
    });

    test('tipo ligado só vale se a categoria também estiver ligada', () {
      var p = const NotificationPreferences().copyWithType(
        PushNotificationType.yourTurn,
        true,
      );
      p = p.copyWithCategory(NotificationCategory.matchmaking, false);
      expect(p.isEnabled(PushNotificationType.yourTurn), isFalse);
      p = p.copyWithCategory(NotificationCategory.matchmaking, true);
      expect(p.isEnabled(PushNotificationType.yourTurn), isTrue);
    });
  });

  group('categorias', () {
    test('cada categoria liga e desliga sozinha', () {
      for (final c in NotificationCategory.values) {
        final off = const NotificationPreferences().copyWithCategory(c, false);
        expect(off.isCategoryEnabled(c), isFalse, reason: c.name);
        for (final other in NotificationCategory.values.where((o) => o != c)) {
          expect(
            off.isCategoryEnabled(other),
            isTrue,
            reason: '${c.name} -> ${other.name}',
          );
        }
        expect(off.copyWithCategory(c, true), const NotificationPreferences());
      }
    });
  });

  group('imutabilidade e igualdade', () {
    test('copyWith devolve outro objeto e não mexe no original', () {
      const base = NotificationPreferences();
      final changed = base.copyWithCategory(NotificationCategory.teams, false);
      expect(changed, isNot(base));
      expect(base.teamsEnabled, isTrue);
    });

    test('mesmos valores são iguais', () {
      final a = const NotificationPreferences().copyWithType(
        PushNotificationType.yourTurn,
        false,
      );
      const b = NotificationPreferences(queueTurnEnabled: false);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
