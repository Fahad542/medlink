import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Converts exceptions and noisy API strings into short, user-safe messages.
abstract final class UserFacingErrors {
  UserFacingErrors._();

  static const String generic =
      'Something went wrong. Please try again.';

  static const String network =
      'No internet connection. Check your network and try again.';

  /// Use in [catch] blocks instead of [Object.toString].
  static String forException(Object error) {
    if (error is SignInWithAppleAuthorizationException) {
      return _appleAuth(error);
    }
    if (error is SocketException) {
      return network;
    }
    if (error is HttpException) {
      return generic;
    }
    if (error is PlatformException) {
      return _platformException(error);
    }
    if (error is StateError) {
      final m = error.message;
      if (m.contains('APPLE_SERVICE_ID') ||
          m.contains('Apple Sign-In on Android')) {
        return 'Apple Sign-In isn\'t set up on this device. Try Google or email.';
      }
      return generic;
    }
    if (error is FormatException) {
      return generic;
    }

    final raw = error.toString();
    if (_looksTechnical(raw)) {
      return generic;
    }
    final cleaned = raw.replaceFirst(RegExp(r'^(Exception|Error):\s*'), '').trim();
    if (cleaned.length <= 140 && !_looksTechnical(cleaned)) {
      return cleaned;
    }
    return generic;
  }

  /// [raw] from API `message` field — keep short human text; hide stack traces / HTML / errors.
  static String forApiMessage(
    String? raw, {
    String fallback = generic,
  }) {
    if (raw == null) return fallback;
    final t = raw.trim();
    if (t.isEmpty) return fallback;
    if (_looksTechnical(t)) return fallback;
    if (t.length > 180) return fallback;
    return t;
  }

  static String _appleAuth(SignInWithAppleAuthorizationException e) {
    switch (e.code) {
      case AuthorizationErrorCode.canceled:
        return 'Sign in was cancelled.';
      case AuthorizationErrorCode.failed:
        return 'Apple Sign-In failed. Please try again.';
      case AuthorizationErrorCode.invalidResponse:
        return 'Could not complete sign in. Please try again.';
      case AuthorizationErrorCode.notHandled:
        return 'Apple Sign-In could not be started. Try another sign-in method.';
      case AuthorizationErrorCode.unknown:
      default:
        return 'Could not sign in with Apple. Please try again or use another method.';
    }
  }

  static String _platformException(PlatformException e) {
    final code = e.code.toLowerCase();
    final msg = e.message?.toLowerCase() ?? '';
    if (code.contains('network') || msg.contains('network')) {
      return network;
    }
    if (code == 'sign_in_canceled' ||
        code == 'error_canceled' ||
        msg.contains('canceled') ||
        msg.contains('cancelled')) {
      return 'Sign in was cancelled.';
    }
    final detail = e.message?.trim();
    if (detail != null &&
        detail.isNotEmpty &&
        detail.length < 100 &&
        !_looksTechnical(detail)) {
      return detail;
    }
    return generic;
  }

  static bool _looksTechnical(String s) {
    final lower = s.toLowerCase();
    if (RegExp(r'\w+Exception\s*\(').hasMatch(s)) return true;
    if (lower.contains('stacktrace')) return true;
    if (lower.contains('signinwithapple')) return true;
    if (lower.contains('authorizationerrorcode')) return true;
    if (lower.contains('com.apple.')) return true;
    if (lower.contains('authenticationervices')) return true;
    if (lower.contains('dioexception')) return true;
    if (lower.contains('clientexception')) return true;
    if (lower.contains('socketexception')) return true;
    if (lower.contains('failed host lookup')) return true;
    if (lower.contains('handshakeexception')) return true;
    if (lower.contains('statuscode:')) return true;
    if (lower.contains('is not a subtype')) return true;
    if (lower.contains('null check operator')) return true;
    if (lower.contains('bad state')) return true;
    if (lower.contains('type \'') && lower.contains('is not a')) return true;
    if (s.startsWith('{') && s.contains('error')) return true;
    if (RegExp(r'^\s*#\d+\s+').hasMatch(s)) return true;
    if (s.length > 220) return true;
    return false;
  }
}
