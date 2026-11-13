import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Push message received from Firebase Cloud Messaging. The backend sends
/// `notification_id`, `type`, `severity` and, when present, `equipment_id` and `alert_id`.
class PushMessage {
  const PushMessage({this.notificationId, this.type, this.equipmentId, this.title, this.body});

  factory PushMessage.fromRemote(RemoteMessage message) {
    final data = message.data;
    return PushMessage(
      notificationId: int.tryParse('${data['notification_id'] ?? ''}'),
      type: data['type'] as String?,
      equipmentId: int.tryParse('${data['equipment_id'] ?? ''}'),
      title: message.notification?.title,
      body: message.notification?.body,
    );
  }

  final int? notificationId;
  final String? type;
  final int? equipmentId;
  final String? title;
  final String? body;
}

/// Wrapper of the Firebase Messaging SDK (permission, token and incoming messages).
class PushMessaging {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  String get platform => defaultTargetPlatform == TargetPlatform.iOS ? 'IOS' : 'ANDROID';

  /// Asks for the notification permission (Android 13+ and iOS show a dialog).
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return _allowed(settings.authorizationStatus);
  }

  Future<bool> isAllowed() async => _allowed((await _messaging.getNotificationSettings()).authorizationStatus);

  // The backend sends with registration tokens (Firebase Admin multicast). The newer
  // register()/onRegistered API returns an installation ID (FID) for direct-send,
  // which the backend does not support yet, so the token API is kept on purpose.
  // ignore: deprecated_member_use
  Future<String?> token() => _messaging.getToken();

  // ignore: deprecated_member_use
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// Messages that arrive while the app is open (Android does not show them by itself).
  Stream<PushMessage> get onForeground => FirebaseMessaging.onMessage.map(PushMessage.fromRemote);

  /// The technician tapped a push while the app was in the background.
  Stream<PushMessage> get onOpened => FirebaseMessaging.onMessageOpenedApp.map(PushMessage.fromRemote);

  /// The push that opened the app when it was closed, if any.
  Future<PushMessage?> initialMessage() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : PushMessage.fromRemote(message);
  }

  bool _allowed(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized || status == AuthorizationStatus.provisional;
}
