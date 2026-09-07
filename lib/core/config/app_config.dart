import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/config/app_environment.dart';

class AppConfig extends Equatable {
  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.appLinkHost,
    required this.firebaseEnabled,
    required this.verboseLogging,
  });

  static const String _publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const String _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static AppConfig fromEnvironment() {
    final environment = AppEnvironment.resolve();
    return AppConfig(
      environment: environment,
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabasePublishableKey: _publishableKey.isNotEmpty
          ? _publishableKey
          : _anonKey,
      appLinkHost: const String.fromEnvironment('APP_LINK_HOST'),
      firebaseEnabled: const bool.fromEnvironment('FIREBASE_ENABLED'),
      verboseLogging: const bool.fromEnvironment(
        'VERBOSE_LOGGING',
        defaultValue: true,
      ),
    );
  }

  final AppEnvironment environment;
  final String supabaseUrl;
  final String supabasePublishableKey;
  final String appLinkHost;
  final bool firebaseEnabled;
  final bool verboseLogging;

  bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  bool get hasAppLinkHost => appLinkHost.isNotEmpty;

  List<String> get missingRequiredKeys => <String>[
    if (supabaseUrl.isEmpty) 'SUPABASE_URL',
    if (supabasePublishableKey.isEmpty) 'SUPABASE_PUBLISHABLE_KEY',
  ];

  bool get isUsable =>
      hasSupabase || !environment.requiresCompleteConfiguration;

  @override
  List<Object?> get props => <Object?>[
    environment,
    supabaseUrl,
    supabasePublishableKey,
    appLinkHost,
    firebaseEnabled,
    verboseLogging,
  ];
}
