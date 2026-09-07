class AuthRedirects {
  const AuthRedirects._();

  static const String mobileScheme = 'com.lucasdiogof.fifaqueue';
  static const String mobileCallback = '$mobileScheme://auth-callback';
  static const String passwordResetPath = '/reset-password';

  static String passwordReset({
    required bool isWeb,
    required Uri currentUri,
    String appLinkHost = '',
  }) {
    if (!isWeb) {
      return mobileCallback;
    }
    if (appLinkHost.isNotEmpty) {
      return 'https://$appLinkHost$passwordResetPath';
    }
    if (!currentUri.hasScheme || !currentUri.scheme.startsWith('http')) {
      return mobileCallback;
    }
    return '${currentUri.origin}$passwordResetPath';
  }
}
