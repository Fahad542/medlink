/// Apple Sign-In on **Android** (and some web flows) needs a **Services ID** and
/// **HTTPS redirect** in Apple Developer. Pass at build time, e.g.:
/// `flutter run --dart-define=APPLE_SERVICE_ID=com.example.medlink.signin --dart-define=APPLE_REDIRECT_URI=https://your.domain/apple/callback`
class AppleSignInConfig {
  AppleSignInConfig._();

  static const String serviceId = String.fromEnvironment(
    'APPLE_SERVICE_ID',
    defaultValue: '',
  );

  static const String redirectUri = String.fromEnvironment(
    'APPLE_REDIRECT_URI',
    defaultValue: '',
  );
}
