import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pushes the device FCM token to `PATCH /common/fcm-token` when [user_session_v2] exists
/// (any role: patient, doctor, driver). [NetworkApiService] adds `Authorization: Bearer …`.
class FcmTokenBackendSync {
  FcmTokenBackendSync._();

  static const _sessionKey = 'user_session_v2';

  /// [fcmToken] from [NotificationServices.getDeviceToken] / [onTokenRefresh]; if omitted, calls [FirebaseMessaging.getToken].
  static Future<void> trySyncToBackend([String? fcmToken]) async {
    final sp = await SharedPreferences.getInstance();
    final session = sp.getString(_sessionKey);
    if (session == null || session.isEmpty) return;

    String? token = fcmToken;
    if (token == null || token.isEmpty) {
      try {
        token = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        if (kDebugMode) debugPrint('FcmTokenBackendSync getToken: $e');
        return;
      }
    }
    if (token == null || token.isEmpty) return;

    try {
      await ApiServices().updateFcmToken(token);
      if (kDebugMode) debugPrint('FcmTokenBackendSync: server saved FCM token');
    } catch (e) {
      if (kDebugMode) debugPrint('FcmTokenBackendSync: $e');
    }
  }
}
