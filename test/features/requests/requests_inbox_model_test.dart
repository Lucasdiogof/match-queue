import 'package:fifa_queue/features/requests/data/models/invite_target_preview_model.dart';
import 'package:fifa_queue/features/requests/data/models/requests_inbox_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RequestsInboxModel.fromJson', () {
    test('listas ausentes viram listas vazias, nunca null', () {
      final inbox = RequestsInboxModel.fromJson(<String, dynamic>{
        'invitations_received': null,
        'join_requests_to_review': null,
      });

      expect(inbox.invitationsReceived, isEmpty);
      expect(inbox.joinRequestsToReview, isEmpty);
      expect(inbox.pendingCount, 0);
    });

    test('parseia convite e pedido com todos os campos', () {
      final inbox = RequestsInboxModel.fromJson(<String, dynamic>{
        'invitations_received': <dynamic>[
          <String, dynamic>{
            'id': 'inv-1',
            'team_id': 'team-1',
            'team_name': 'Lucksrei FC',
            'team_tag': 'LUC',
            'team_logo_url': 'https://example.com/logo.png',
            'member_count': 7,
            'fc_account_name': 'Luclown',
            'created_at': '2026-09-13T10:00:00Z',
          },
        ],
        'join_requests_to_review': <dynamic>[
          <String, dynamic>{
            'id': 'req-1',
            'team_id': 'team-2',
            'team_name': 'Outro Time',
            'requester_user_id': 'user-1',
            'requester_display_name': 'Lucas',
            'requester_avatar_url': null,
            'fc_account_name': 'Pedro FC',
            'created_at': '2026-09-13T11:00:00Z',
          },
        ],
      });

      expect(inbox.pendingCount, 2);
      final invitation = inbox.invitationsReceived.single;
      expect(invitation.teamName, 'Lucksrei FC');
      expect(invitation.memberCount, 7);
      expect(invitation.fcAccountName, 'Luclown');

      final request = inbox.joinRequestsToReview.single;
      expect(request.requesterDisplayName, 'Lucas');
      expect(request.fcAccountName, 'Pedro FC');
    });
  });

  group('InviteTargetPreviewModel.fromJson', () {
    test('found=false nunca preenche identidade', () {
      final preview = InviteTargetPreviewModel.fromJson(<String, dynamic>{
        'found': false,
      });

      expect(preview.found, isFalse);
      expect(preview.userId, isNull);
      expect(preview.displayName, isNull);
    });

    test('found=true preenche identidade minima', () {
      final preview = InviteTargetPreviewModel.fromJson(<String, dynamic>{
        'found': true,
        'user_id': 'user-1',
        'display_name': 'Lucas',
        'avatar_url': null,
        'fc_account_name': 'Luclown',
      });

      expect(preview.found, isTrue);
      expect(preview.userId, 'user-1');
      expect(preview.displayName, 'Lucas');
      expect(preview.fcAccountName, 'Luclown');
    });
  });
}
