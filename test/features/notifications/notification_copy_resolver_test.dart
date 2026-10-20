import 'package:fifa_queue/features/notifications/domain/entities/app_notification.dart';
import 'package:fifa_queue/features/notifications/domain/entities/notification_category.dart';
import 'package:fifa_queue/features/notifications/presentation/notification_copy_resolver.dart';
import 'package:fifa_queue/l10n/generated/app_localizations_en.dart';
import 'package:fifa_queue/l10n/generated/app_localizations_es.dart';
import 'package:fifa_queue/l10n/generated/app_localizations_pt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AppNotification _n(String key, [Map<String, dynamic> params = const {}]) =>
    AppNotification(
      id: 'n1',
      category: NotificationCategory.teams,
      type: 'T',
      titleKey: key,
      params: params,
      createdAt: DateTime.utc(2026, 10, 17),
    );

void main() {
  final pt = AppLocalizationsPt();
  final en = AppLocalizationsEn();
  final es = AppLocalizationsEs();

  group('textFor', () {
    test('monta o texto com os parâmetros no idioma do app', () {
      final n = _n('notification_team_member_joined', {
        'display_name': 'Ana',
        'team_name': 'Os Brabos',
      });
      expect(
        NotificationCopyResolver.textFor(pt, n),
        'Ana entrou em Os Brabos.',
      );
      expect(NotificationCopyResolver.textFor(en, n), 'Ana joined Os Brabos.');
      expect(NotificationCopyResolver.textFor(es, n), contains('Ana'));
      expect(NotificationCopyResolver.textFor(es, n), contains('Os Brabos'));
    });

    test('inteiros chegam como número, texto ou lixo, sem derrubar', () {
      String run(Object? wins, Object? losses) =>
          NotificationCopyResolver.textFor(
            pt,
            _n('notification_weekend_league_finished', {
              'display_name': 'Ana',
              'wins': wins,
              'losses': losses,
            }),
          );
      expect(run(15, 5), 'Ana terminou o Champions em 15-5.');
      expect(run(15.6, '5'), 'Ana terminou o Champions em 16-5.');
      expect(run('x', null), 'Ana terminou o Champions em 0-0.');
    });

    test('parâmetro ausente ou vazio vira texto vazio, nunca "null"', () {
      final t = NotificationCopyResolver.textFor(
        pt,
        _n('notification_team_member_joined', {
          'display_name': '',
          'team_name': 3,
        }),
      );
      expect(t, isNot(contains('null')));
      expect(t, ' entrou em .');
    });

    test('chave desconhecida cai no próprio nome da chave', () {
      expect(
        NotificationCopyResolver.textFor(pt, _n('notification_do_futuro')),
        'notification_do_futuro',
      );
    });

    test('mensagem sem parâmetros também funciona', () {
      final t = NotificationCopyResolver.textFor(
        pt,
        _n('notification_you_are_team_leader'),
      );
      expect(t, pt.notificationYouAreTeamLeader);
    });

    test('divisão desconhecida mostra o valor cru em vez de quebrar', () {
      final t = NotificationCopyResolver.textFor(
        pt,
        _n('notification_rivals_division_changed', {
          'display_name': 'Ana',
          'division': 'DIV_999',
        }),
      );
      expect(t, contains('DIV_999'));
    });

    test('cada chave conhecida produz um texto que não é a própria chave', () {
      const keys = [
        'notification_team_member_joined',
        'notification_team_leader_changed',
        'notification_you_are_team_leader',
        'notification_team_top_scorer_changed',
        'notification_team_top_assist_changed',
        'notification_weekend_league_finished',
        'notification_rivals_division_changed',
        'notification_team_join_request_received',
        'notification_team_join_request_approved',
        'notification_team_join_request_rejected',
        'notification_team_invitation_received',
        'notification_team_invitation_accepted',
      ];
      for (final l10n in [pt, en, es]) {
        for (final k in keys) {
          final t = NotificationCopyResolver.textFor(
            l10n,
            _n(k, {'division': 'DIV_10'}),
          );
          expect(t, isNot(k), reason: '$k em ${l10n.localeName}');
          expect(t.trim(), isNotEmpty);
        }
      }
    });
  });

  group('iconFor', () {
    test('cada categoria tem seu ícone e a ausência tem o padrão', () {
      final icons = {
        for (final c in NotificationCategory.values)
          c: NotificationCopyResolver.iconFor(c),
      };
      expect(
        icons.values.toSet(),
        hasLength(NotificationCategory.values.length),
      );
      expect(
        NotificationCopyResolver.iconFor(null),
        Icons.notifications_outlined,
      );
      expect(icons.values, isNot(contains(Icons.notifications_outlined)));
    });
  });
}
