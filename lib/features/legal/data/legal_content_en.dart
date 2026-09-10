import 'package:fifa_queue/features/legal/data/legal_content_pt.dart'
    show kResponsibleParty, kSupportEmail;
import 'package:fifa_queue/features/legal/domain/legal_document.dart';

const String _nonAffiliationEn =
    'FIFA Queue is an independent, fan-made application and is not '
    'affiliated with, endorsed by, or sponsored by EA SPORTS, Electronic '
    'Arts, FIFA, or any of their affiliates. All third-party trademarks, '
    'names, and imagery mentioned belong to their respective owners and '
    'are used solely to identify what the app is about.';

const LegalDocument kPrivacyPolicyEn = LegalDocument(
  updatedAt: '2026-09-10',
  nonAffiliationDisclaimer: _nonAffiliationEn,
  sections: <LegalSection>[
    LegalSection(
      title: '1. Who runs this app',
      body:
          'FIFA Queue is operated by $kResponsibleParty. '
          'Questions about this Policy can be sent to '
          '$kSupportEmail.',
    ),
    LegalSection(
      title: '2. What data we collect',
      body:
          'We only collect what the app needs to work:\n\n'
          '• Account data: email and password (stored securely by our '
          'authentication provider, never in plain text).\n'
          '• Profile: your display name.\n'
          '• Internal identifiers: a unique ID generated for you and for '
          'each Team/Account you create or join.\n'
          '• Accounts: the names you give your Accounts (the in-game '
          'profiles you register and manage in FIFA Queue), the squad you '
          'build for each one, Rivals division, and Weekend League '
          'records you enter yourself.\n'
          '• Teams: name, tag, and activity history of the teams you '
          'belong to.\n'
          '• Match data: match searches, queues, results, and stats '
          '(goals, assists) that you or your team record.\n'
          '• Push notification token (Firebase Cloud Messaging), if you '
          'allow notifications.\n'
          '• Public profile: if you turn this on in settings, you choose '
          'a public address and one Account to link to it; the link shows '
          'your name and that Account, and you individually decide '
          'whether it also shows the squad, Rivals division, Weekend '
          'League record, and stats for that Account.',
    ),
    LegalSection(
      title: '3. Providers we use',
      body:
          'We use Supabase (database, authentication, and API hosting) '
          'and Firebase (push notifications and crash reporting). These '
          'providers process data on our behalf under their own security '
          'policies and are not allowed to use your data for their own '
          'purposes.',
    ),
    LegalSection(
      title: '4. Why we use your data',
      body:
          'We use the data we collect exclusively to: authenticate your '
          'account; run your team\'s match search queue; show your '
          'history and stats; send notifications about your turn in the '
          'queue or team events (if you allow it); and, if you enable a '
          'public profile, display on it whatever you choose to show. We '
          'do not sell your data or use it for advertising.',
    ),
    LegalSection(
      title: '5. Storage and security',
      body:
          'Data is stored on Supabase servers, protected by Row Level '
          'Security: each user can only read/edit what belongs to them or '
          'what their team shares with them. Passwords are never stored '
          'in plain text. Communication between the app and the server is '
          'always over HTTPS.',
    ),
    LegalSection(
      title: '6. Retention',
      body:
          'We keep your data for as long as your account exists. Your '
          'team\'s match history is kept even after you delete your '
          'account, but anonymized (with your name removed) so we don\'t '
          'erase the shared history of the other team members.',
    ),
    LegalSection(
      title: '7. Account deletion',
      body:
          'You can delete your account at any time under Profile → '
          'Delete my account. Deletion removes your profile, Accounts, '
          'squads, team memberships, registered devices, notification '
          'preferences, and public profile. If you are the sole member of '
          'a team you created, the whole team is removed; if there are '
          'other members, deletion is only allowed once you are no longer '
          'the sole owner. This action is permanent and cannot be undone.',
    ),
    LegalSection(
      title: '8. Data sharing',
      body:
          'We do not share your data with third parties for marketing. '
          'We only share data with the infrastructure providers listed in '
          'section 3, to the extent needed for the app to work, and when '
          'required by law.',
    ),
    LegalSection(
      title: '9. Your rights',
      body:
          'You can, at any time: access and edit your display name from '
          'within the app; turn your public profile on or off and choose '
          'what it shows (the linked Account, squad, Rivals division, '
          'Weekend League record, and stats); and delete your account and '
          'its associated data. For any other request about your data, '
          'contact us at $kSupportEmail.',
    ),
    LegalSection(
      title: '10. Children',
      body:
          'FIFA Queue is not directed at children under 13 and does not '
          'knowingly collect data from them. If you are a parent or '
          'guardian and believe a child has provided us personal data, '
          'please contact us so we can remove it.',
    ),
    LegalSection(
      title: '11. Changes to this policy',
      body:
          'We may update this Policy from time to time. Material changes '
          'will be communicated inside the app. The date at the top of '
          'this page always reflects the latest version.',
    ),
    LegalSection(
      title: '12. Trademarks and affiliation',
      body: _nonAffiliationEn,
    ),
  ],
);

const LegalDocument kTermsOfUseEn = LegalDocument(
  updatedAt: '2026-09-08',
  nonAffiliationDisclaimer: _nonAffiliationEn,
  sections: <LegalSection>[
    LegalSection(
      title: '1. Acceptance of terms',
      body:
          'By creating an account or using FIFA Queue, you agree to these '
          'Terms of Use and our Privacy Policy. If you do not agree, '
          'please do not use the app.',
    ),
    LegalSection(
      title: '2. About the app',
      body:
          'FIFA Queue helps groups of EA SPORTS FC / Clubs players '
          'organize who searches for a match at any given time, and lets '
          'them record results, accounts, and team stats.',
    ),
    LegalSection(
      title: '3. Your account',
      body:
          'You are responsible for keeping your password confidential and '
          'for all activity under your account. You must provide accurate '
          'information when signing up.',
    ),
    LegalSection(
      title: '4. User conduct',
      body:
          'You agree not to use the app to harass other users, post '
          'offensive content, attempt to access other people\'s accounts, '
          'or interfere with the normal operation of the service.',
    ),
    LegalSection(
      title: '5. Matchmaking and queue',
      body:
          'The match search queue is organized automatically by the app '
          'based on arrival order. FIFA Queue does not take part in, '
          'interfere with, or take responsibility for the outcome of '
          'matches played outside the app.',
    ),
    LegalSection(
      title: '6. Content you submit',
      body:
          'You are responsible for the account names, results, and other '
          'information you enter into the app. We reserve the right to '
          'remove content that is clearly offensive or that violates '
          'these Terms.',
    ),
    LegalSection(
      title: '7. Third-party content',
      body:
          'Player names, clubs, leagues, and other EA SPORTS FC '
          'references shown in the app are used solely for informational/'
          'organizational purposes and belong to their respective owners, '
          'as detailed in the trademark section below.',
    ),
    LegalSection(
      title: '8. Service availability',
      body:
          'We do our best to keep the app available, but we do not '
          'guarantee uninterrupted or error-free operation. Maintenance, '
          'updates, or third-party outages (Supabase, Firebase, app '
          'stores) may cause temporary downtime.',
    ),
    LegalSection(
      title: '9. Suspension and termination',
      body:
          'We may suspend or terminate access for an account that '
          'violates these Terms. You can close your account at any time '
          'via the account deletion feature described in the Privacy '
          'Policy.',
    ),
    LegalSection(
      title: '10. Intellectual property',
      body:
          'The code, design, and "FIFA Queue" brand belong to the app\'s '
          'developer. Third-party trademarks (EA SPORTS, FIFA, Ultimate '
          'Team, and similar) belong to their respective owners, as '
          'described in the trademark section below.',
    ),
    LegalSection(
      title: '11. Limitation of liability',
      body:
          'The app is provided "as is". To the maximum extent permitted '
          'by law, we are not liable for indirect damages arising from '
          'the use or inability to use the app.',
    ),
    LegalSection(
      title: '12. Changes to these Terms',
      body:
          'We may update these Terms from time to time. Continued use of '
          'the app after an update means you accept the new Terms.',
    ),
    LegalSection(
      title: '13. Contact',
      body: 'Questions about these Terms: $kSupportEmail.',
    ),
    LegalSection(
      title: '14. Trademarks and affiliation',
      body: _nonAffiliationEn,
    ),
  ],
);
