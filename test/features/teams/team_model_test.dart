import 'package:fifa_queue/features/teams/data/models/team_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseString', () {
    test('só aceita texto não vazio', () {
      expect(TeamModel.parseString('abc'), 'abc');
      expect(TeamModel.parseString(''), isNull);
      expect(TeamModel.parseString(null), isNull);
      expect(TeamModel.parseString(42), isNull);
    });
  });

  group('parseDate', () {
    test('lê ISO e normaliza para UTC', () {
      final d = TeamModel.parseDate('2026-10-17T21:00:00-03:00');
      expect(d.isUtc, isTrue);
      expect(d, DateTime.utc(2026, 10, 18));
    });

    test('valor inválido usa o fallback, quando existe', () {
      final fb = DateTime.utc(2020);
      expect(TeamModel.parseDate('lixo', fallback: fb), fb);
      expect(TeamModel.parseDate(null, fallback: fb), fb);
    });

    test('sem fallback, usa agora em UTC', () {
      final before = DateTime.now().toUtc();
      final d = TeamModel.parseDate(null);
      expect(d.isUtc, isTrue);
      expect(d.isBefore(before.subtract(const Duration(seconds: 1))), isFalse);
    });
  });

  group('fromJson', () {
    final json = <String, dynamic>{
      'id': 't1',
      'name': 'Os Brabos',
      'tag': 'BRB',
      'logo_url': 'https://x/logo.png',
      'primary_color': '#112233',
      'secondary_color': '#445566',
      'default_search_duration_seconds': 300,
      'is_active': false,
      'is_public': false,
      'created_at': '2026-10-01T10:00:00Z',
      'updated_at': '2026-10-02T10:00:00Z',
    };

    test('lê todos os campos', () {
      final t = TeamModel.fromJson(json);
      expect(t.id, 't1');
      expect(t.name, 'Os Brabos');
      expect(t.tag, 'BRB');
      expect(t.logoUrl, 'https://x/logo.png');
      expect(t.primaryColor, '#112233');
      expect(t.secondaryColor, '#445566');
      expect(t.defaultSearchDuration, const Duration(seconds: 300));
      expect(t.isActive, isFalse);
      expect(t.isPublic, isFalse);
      expect(t.createdAt, DateTime.utc(2026, 10, 1, 10));
      expect(t.updatedAt, DateTime.utc(2026, 10, 2, 10));
    });

    test('campos ausentes caem nos padrões: 180 s, ativo e público', () {
      final t = TeamModel.fromJson({
        'id': 't',
        'name': 'N',
        'created_at': '2026-10-01T10:00:00Z',
      });
      expect(t.defaultSearchDuration, const Duration(seconds: 180));
      expect(t.isActive, isTrue);
      expect(t.isPublic, isTrue);
      expect(t.tag, isNull);
      expect(t.logoUrl, isNull);
    });

    test('sem updated_at usa a data de criação', () {
      final t = TeamModel.fromJson({
        'id': 't',
        'name': 'N',
        'created_at': '2026-10-01T10:00:00Z',
      });
      expect(t.updatedAt, t.createdAt);
    });

    test('tipos errados não derrubam: viram padrão', () {
      final t = TeamModel.fromJson({
        'id': 1,
        'name': 'N',
        'default_search_duration_seconds': '999',
        'is_active': 'sim',
        'created_at': '2026-10-01T10:00:00Z',
      });
      expect(t.id, '1');
      expect(t.defaultSearchDuration, const Duration(seconds: 180));
      expect(t.isActive, isTrue);
    });
  });

  group('summaryFromJson', () {
    test('lê o resumo público e zera a contagem quando não for inteira', () {
      final s = TeamModel.summaryFromJson({
        'id': 't1',
        'name': 'Os Brabos',
        'member_count': 7,
      });
      expect(s.memberCount, 7);
      expect(s.name, 'Os Brabos');
      expect(
        TeamModel.summaryFromJson({
          'id': 't',
          'name': 'N',
          'member_count': 'x',
        }).memberCount,
        0,
      );
    });
  });

  group('publicTeamFromJson', () {
    test('found=false devolve um time vazio', () {
      final t = TeamModel.publicTeamFromJson({
        'found': false,
        'team': {'id': 'x'},
      });
      expect(t.found, isFalse);
      expect(t.id, isNull);
      expect(t.members, isEmpty);
    });

    test('found ausente também conta como não encontrado', () {
      expect(TeamModel.publicTeamFromJson(<String, dynamic>{}).found, isFalse);
    });

    test('lê o time e os membros, ignorando entradas que não são mapas', () {
      final t = TeamModel.publicTeamFromJson({
        'found': true,
        'team': {
          'id': 't1',
          'name': 'Os Brabos',
          'tag': 'BRB',
          'member_count': 2,
        },
        'members': [
          {
            'display_name': 'Ana',
            'role': 'LEADER',
            'slug': 'ana',
            'avatar_url': 'https://x/a.png',
          },
          'lixo',
          {'display_name': 'Beto', 'role': 'MEMBER'},
        ],
      });
      expect(t.found, isTrue);
      expect(t.id, 't1');
      expect(t.tag, 'BRB');
      expect(t.memberCount, 2);
      expect(t.members.map((m) => m.displayName), ['Ana', 'Beto']);
      expect(t.members.first.publicProfileSlug, 'ana');
      expect(t.members.last.publicProfileSlug, isNull);
    });

    test('members que não é lista vira lista vazia', () {
      final t = TeamModel.publicTeamFromJson({
        'found': true,
        'team': {'id': 't1', 'name': 'N'},
        'members': 'x',
      });
      expect(t.members, isEmpty);
    });
  });
}
