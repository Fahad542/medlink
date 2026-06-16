import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:medlink/core/constants/apple_sign_in_config.dart';
import 'package:medlink/services/apple_sign_in_profile_cache.dart';
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

    final given = credential.givenName?.trim() ?? '';
    final family = credential.familyName?.trim() ?? '';
    final nameFromApple = '$given $family'.trim();

    // Apple sends email + name only on the *first* sign-in for this app.
    // Reuse values we stored on device for this Apple user id.
    final cached = await AppleSignInProfileCache.read(userId);

    var email = credential.email?.trim() ?? '';
    if (email.isEmpty) {
      final c = cached.email?.trim();
      if (c != null && c.isNotEmpty) {
        email = c;
      }
    }
    if (email.isEmpty) {
      email = _syntheticAppleEmail(userId);
    }

    var fullName = nameFromApple;
    if (fullName.isEmpty) {
      final n = cached.fullName?.trim();
      if (n != null && n.isNotEmpty) {
        fullName = n;
      }
    }
    if (fullName.isEmpty) {
      if (email.isNotEmpty && !_isPlaceholderAppleEmail(email)) {
        fullName = email.split('@').first;
      } else {
        fullName = 'Apple User';
      }
    }

    // Persist first-time payload for next launches (Apple won't resend it).
    await AppleSignInProfileCache.writeFromCredential(
      appleUserIdentifier: userId,
      email: credential.email?.trim(),
      fullName: nameFromApple.isNotEmpty ? nameFromApple : null,
    );

    return SocialAppleAccount(
      providerUserId: 'apple|$userId',
      email: email,
      fullName: fullName,
    );
  }

  /// True when [email] is our API placeholder (not a real Apple relay address).
  static bool _isPlaceholderAppleEmail(String email) {
    final e = email.trim().toLowerCase();
    return e.endsWith('@example.com') && e.startsWith('apple');
  }

  /// Short RFC-shaped placeholder when Apple omits email on repeat sign-in.
  /// Uniqueness: deterministic hash of Apple `userIdentifier` (backend keys on `providerUserId`).
  static String _syntheticAppleEmail(String appleUserIdentifier) {
    final safe = appleUserIdentifier
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toLowerCase();
    if (safe.isEmpty) return 'apple.unknown@example.com';
    var h = 0x811c9dc5;
    for (final u in safe.codeUnits) {
      h ^= u;
      h = (h * 0x01000193) & 0x7fffffff;
    }
    final tag = h.toRadixString(16).padLeft(8, '0');
    return 'apple.$tag@example.com';
  }
}
