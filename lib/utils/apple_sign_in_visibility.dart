import 'package:flutter/foundation.dart';

/// Sign in with Apple is only shown on native **iOS** (iPhone / iPad), not on Android or web.
bool get showAppleSignInButton =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
