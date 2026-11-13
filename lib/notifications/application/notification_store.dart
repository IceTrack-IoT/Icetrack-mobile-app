import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/state/app_state.dart';
import '../../shared/infrastructure/api_exception.dart';
import '../domain/model/app_notification.dart';
import '../infrastructure/assemblers/notification_assembler.dart';
import '../infrastructure/notifications_api.dart';
import '../infrastructure/push_messaging.dart';
import '../infrastructure/resources/notification_resources.dart';

/// Application service of the Notifications context: inbox (US-43, US-44) and
/// push registration with Firebase Cloud Messaging (US-32).
class NotificationStore extends ChangeNotifier {
  NotificationStore._();

  static final NotificationStore instance = NotificationStore._();

  final NotificationsApi _api = NotificationsApi();
  final PushMessaging _push = PushMessaging();

  List<AppNotification> items = [];
  int unreadCount = 0;
  bool isLoading = false;
  bool hasLoaded = false;
  ApiException? loadError;

  /// Whether the technician allowed notifications on this phone.
  bool pushAllowed = false;
  String? _registeredToken;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  /// Set by the presentation layer: shows a push received with the app open.
  void Function(PushMessage message)? onForegroundPush;

  /// Set by the presentation layer: opens the order or unit of a tapped push.
  void Function(PushMessage message)? onPushOpened;

  Future<void> refresh() async {
    if (isLoading || AppState.instance.isOffline) return;
    isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([_api.list(), _api.unreadCount()]);
      items = (results[0] as PagedNotificationResource).items.map(NotificationAssembler.toEntity).toList();
      unreadCount = results[1] as int;
      loadError = null;
      hasLoaded = true;
    } on ApiException catch (e) {
      loadError = e;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<AppNotification> load(int id) async => NotificationAssembler.toEntity(await _api.getById(id));

  Future<void> markRead(AppNotification notification) async {
    if (notification.isRead) return;
    await _api.markRead(notification.id);
    _replace(notification.markedRead());
    if (unreadCount > 0) unreadCount--;
    notifyListeners();
  }

  Future<void> markAllRead() async {
    unreadCount = await _api.markAllRead();
    items = items.map((n) => n.markedRead()).toList();
    notifyListeners();
  }

  Future<void> dismiss(AppNotification notification) async {
    items.removeWhere((n) => n.id == notification.id);
    if (!notification.isRead && unreadCount > 0) unreadCount--;
    notifyListeners();
    try {
      await _api.dismiss(notification.id);
    } on ApiException {
      await refresh(); // put it back if the backend did not dismiss it
    }
  }

  /// Called once the technician is inside the app: permission, token and listeners.
  Future<void> startPush() async {
    if (_subscriptions.isEmpty) {
      _subscriptions.add(_push.onTokenRefresh.listen(_registerToken));
      _subscriptions.add(_push.onForeground.listen((message) {
        refresh();
        onForegroundPush?.call(message);
      }));
      _subscriptions.add(_push.onOpened.listen((message) => onPushOpened?.call(message)));
    }
    try {
      pushAllowed = await _push.requestPermission();
      notifyListeners();
      final token = await _push.token();
      if (token != null) await _registerToken(token);
      final initial = await _push.initialMessage();
      if (initial != null) onPushOpened?.call(initial);
    } catch (e) {
      // Without Google Play services or connection the app keeps working without push.
      debugPrint('Push registration skipped: $e');
    }
  }

  /// Asks again for the permission (button in the profile).
  Future<void> enablePush() async {
    pushAllowed = await _push.requestPermission();
    notifyListeners();
    if (pushAllowed) {
      final token = await _push.token();
      if (token != null) await _registerToken(token);
    }
  }

  /// On sign-out, before the session is discarded, so this phone stops receiving pushes.
  Future<void> stopPush() async {
    final token = _registeredToken;
    _registeredToken = null;
    if (token == null) return;
    try {
      await _api.unregisterDeviceToken(token);
    } on ApiException {
      // Best effort: the backend also deletes tokens that Firebase reports as dead.
    }
  }

  void reset() {
    items = [];
    unreadCount = 0;
    hasLoaded = false;
    loadError = null;
    notifyListeners();
  }

  Future<void> _registerToken(String token) async {
    await _api.registerDeviceToken(RegisterDeviceTokenResource(token: token, platform: _push.platform));
    _registeredToken = token;
  }

  void _replace(AppNotification notification) {
    final index = items.indexWhere((n) => n.id == notification.id);
    if (index >= 0) items[index] = notification;
  }
}
