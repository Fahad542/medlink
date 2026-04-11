import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:medlink/core/constants/apple_sign_in_config.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Google profile used for `/auth/social-login`.
class SocialGoogleAccount {
  SocialGoogleAccount({
    required this.providerUserId,
    required this.email,
    required this.fullName,
    this.photoUrl,
  });

  final String providerUserId;
  final String email;
  final String fullName;
  final String? photoUrl;
}

class SocialAuthService {
  SocialAuthService._();

  static final GoogleSignIn _google = GoogleSignIn(
    scopes: const <String>['email', 'profile'],
  );

  static Future<SocialGoogleAccount?> signInWithGoogle() async {
    final GoogleSignInAccount? account = await _google.signIn();
    if (account == null) return null;

    final String email = account.email.trim();
    final String id = account.id.trim();
    if (email.isEmpty && id.isEmpty) return null;

    final String sub = id.isNotEmpty ? id : email;
    final String providerUserId = 'google-oauth2|$sub';
    final String fullName = (account.displayName?.trim().isNotEmpty ?? false)
        ? account.displayName!.trim()
        : (email.isNotEmpty ? email.split('@').first : 'User');

    return SocialGoogleAccount(
      providerUserId: providerUserId,
      email: email,
      fullName: fullName,
      photoUrl: account.photoUrl,
    );
  }

  static Future<void> signOutGoogle() async {
    await _google.signOut();
  }
}

/// Apple profile used for `/auth/social-login`.
/// Email/name may be empty after the first sign-in; backend should key on [providerUserId].
class SocialAppleAccount {
  SocialAppleAccount({
    required this.providerUserId,
    required this.email,
    required this.fullName,
  });

  final String providerUserId;
  final String email;
  final String fullName;
}

class SocialAppleAuth {
  SocialAppleAuth._();

  static bool get _isIosOrMacos {
    if (kIsWeb) return false;
    final t = defaultTargetPlatform;
    return t == TargetPlatform.iOS || t == TargetPlatform.macOS;
  }

  static bool get _isAndroid {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
  }

  /// Returns `null` if user cancels or Sign in with Apple is unavailable.
  static Future<SocialAppleAccount?> signInWithApple() async {
    if (kIsWeb) return null;

    late final AuthorizationCredentialAppleID credential;
    if (_isIosOrMacos) {
      // Avoid `isAvailable()` on iOS/macOS — it can throw via MethodChannel on
      // some simulators/builds; `getAppleIDCredential` is the reliable entry point.
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
    } else if (_isAndroid) {
      if (AppleSignInConfig.serviceId.isEmpty ||
          AppleSignInConfig.redirectUri.isEmpty) {
        throw StateError(
          'Apple Sign-In on Android needs dart-defines APPLE_SERVICE_ID and '
          'APPLE_REDIRECT_URI (Services ID + HTTPS redirect URL).',
        );
      }
      var available = false;
      try {
        available = await SignInWithApple.isAvailable();
      } catch (_) {
        available = true;
      }
      if (!available) return null;
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: AppleSignInConfig.serviceId,
          redirectUri: Uri.parse(AppleSignInConfig.redirectUri),
        ),
      );
    } else {
      return null;
    }

    final userId = credential.userIdentifier?.trim() ?? '';
    if (userId.isEmpty) return null;

    final email = credential.email?.trim() ?? '';
    final given = credential.givenName?.trim() ?? '';
    final family = credential.familyName?.trim() ?? '';
    var fullName = '$given $family'.trim();
    if (fullName.isEmpty) {
      fullName =
          email.isNotEmpty ? email.split('@').first : 'Apple User';
    }

    return SocialAppleAccount(
      providerUserId: 'apple|$userId',
      email: email,
      fullName: fullName,
    );
  }
}
