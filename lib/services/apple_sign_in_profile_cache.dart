import 'package:shared_preferences/shared_preferences.dart';

/// Apple sends [email] + [givenName]/[familyName] only on the **first**
/// successful Sign in with Apple for this app. Later sessions return null —
/// we persist the first values per [userIdentifier] and reuse them.
class AppleSignInProfileCache {
  AppleSignInProfileCache._();

  static const _kEmail = 'apple_si_email_';
  static const _kName = 'apple_si_name_';

  static String _safeKey(String appleUserIdentifier) =>
      appleUserIdentifier.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

  static Future<({String? email, String? fullName})> read(
      String appleUserIdentifier) async {
    if (appleUserIdentifier.isEmpty) {
      return (email: null, fullName: null);
    }
    final sp = await SharedPreferences.getInstance();
    final k = _safeKey(appleUserIdentifier);
    return (
      email: sp.getString('$_kEmail$k'),
      fullName: sp.getString('$_kName$k'),
    );
  }

  /// Call when Apple returns real values (usually first sign-in only).
  static Future<void> writeFromCredential({
    required String appleUserIdentifier,
    String? email,
    String? fullName,
  }) async {
    if (appleUserIdentifier.isEmpty) return;
    final sp = await SharedPreferences.getInstance();
    final k = _safeKey(appleUserIdentifier);
    final e = email?.trim();
    if (e != null && e.isNotEmpty) {
      await sp.setString('$_kEmail$k', e);
    }
    final n = fullName?.trim();
    if (n != null && n.isNotEmpty) {
      await sp.setString('$_kName$k', n);
    }
  }
}
