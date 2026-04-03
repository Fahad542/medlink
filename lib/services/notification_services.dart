import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationServices {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
    'medlink_push',
    'Push notifications',
    description: 'MedLink alerts',
    importance: Importance.high,
  );

  static int _localId = 0;

  /// iOS: FCM needs APNs token before [getToken]. This polls briefly after permission.
  Future<void> _waitForApnsTokenIfNeeded() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    const maxAttempts = 40;
    for (var i = 0; i < maxAttempts; i++) {
      final apns = await messaging.getAPNSToken();
      if (apns != null) return;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  /// Required by [flutter_local_notifications] 10+ on Android.
  Future<void> setupLocalNotifications() async {
    if (kIsWeb) return;

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );

    final androidPlugin = _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_androidChannel);
      await androidPlugin.requestNotificationsPermission();
    }
  }

  /// iOS: show alert/sound while app is open (FCM messages that include a [RemoteNotification]).
  Future<void> configureForegroundPresentation() async {
    if (kIsWeb) return;
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> requestNotificationPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted permission');
      }
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      if (kDebugMode) {
        print('User granted provisional permission');
      }
    } else {
      if (kDebugMode) {
        print('User denied permission');
      }
    }
  }

  Future<String?> getDeviceToken() async {
    try {
      await _waitForApnsTokenIfNeeded();
      return await messaging.getToken();
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('getDeviceToken: $e');
        debugPrint('$stack');
      }
      return null;
    }
  }

  void listenForTokenWhenReady(void Function(String token) onToken) {
    messaging.onTokenRefresh.listen(onToken);
  }

  Future<void> _showForegroundLocal(RemoteMessage message) async {
    if (kIsWeb) return;

    final n = message.notification;
    final title = n?.title ?? message.data['title']?.toString();
    final body = n?.body ?? message.data['body']?.toString();
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      if (kDebugMode) {
        debugPrint(
          'FCM: no title/body (use Firebase "notification" fields or data.title / data.body)',
        );
      }
      return;
    }

    // iOS: FCM already shows notification payload in foreground after [configureForegroundPresentation].
    if (defaultTargetPlatform == TargetPlatform.iOS && n != null) {
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _local.show(
        id: _localId++,
        title: title ?? '',
        body: body ?? '',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: 'ic_launcher',
          ),
        ),
      );
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _local.show(
        id: _localId++,
        title: title ?? '',
        body: body ?? '',
        notificationDetails: const NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }

  void firebaseInit() {
    FirebaseMessaging.onMessage.listen((message) async {
      if (kDebugMode) {
        debugPrint('FCM onMessage: ${message.messageId}');
      }
      await _showForegroundLocal(message);
    });
  }
}
