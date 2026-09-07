enum AppEnvironment {
  development('development'),
  staging('staging'),
  production('production');

  const AppEnvironment(this.key);

  final String key;

  static const String _defineKey = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static AppEnvironment resolve() {
    for (final environment in AppEnvironment.values) {
      if (environment.key == _defineKey) {
        return environment;
      }
    }
    return AppEnvironment.development;
  }

  bool get isDevelopment => this == AppEnvironment.development;

  bool get isStaging => this == AppEnvironment.staging;

  bool get isProduction => this == AppEnvironment.production;

  bool get requiresCompleteConfiguration => !isDevelopment;
}
