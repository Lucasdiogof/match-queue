class AuthRedirects {
  const AuthRedirects._();

  static const String passwordResetPath = '/reset-password';

  static String passwordReset({
    required bool isWeb,
    required Uri currentUri,
    required String mobileScheme,
    String appLinkHost = '',
  }) {
    final mobileCallback = '$mobileScheme://auth-callback';
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
