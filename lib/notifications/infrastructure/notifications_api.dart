import '../../shared/infrastructure/api_client.dart';
import 'resources/notification_resources.dart';

/// REST calls of the Notifications bounded context (`/api/v1/notifications/**`).
class NotificationsApi {
  NotificationsApi([ApiClient? client]) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<PagedNotificationResource> list({int page = 0, int size = 50}) async {
    final json = await _client.get('/notifications', query: {'page': '$page', 'size': '$size'});
    return PagedNotificationResource.fromJson(json as Map<String, dynamic>);
  }

  Future<NotificationResource> getById(int id) async =>
      NotificationResource.fromJson(await _client.get('/notifications/$id') as Map<String, dynamic>);

  Future<int> unreadCount() async {
    final json = await _client.get('/notifications/unread-count') as Map<String, dynamic>;
    return (json['unread_count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markRead(int id) async {
    await _client.put('/notifications/$id/read');
  }

  /// Returns the unread count after the change.
  Future<int> markAllRead() async {
    final json = await _client.put('/notifications/read-all') as Map<String, dynamic>;
    return (json['unread_count'] as num?)?.toInt() ?? 0;
  }

  Future<void> dismiss(int id) async {
    await _client.put('/notifications/$id/dismiss');
  }

  /// Idempotent: called on every start and whenever FCM rotates the token.
  Future<void> registerDeviceToken(RegisterDeviceTokenResource resource) async {
    await _client.put('/notifications/device-tokens', body: resource.toJson());
  }

  Future<void> unregisterDeviceToken(String token) async {
    await _client.delete('/notifications/device-tokens', query: {'token': token});
  }
}
