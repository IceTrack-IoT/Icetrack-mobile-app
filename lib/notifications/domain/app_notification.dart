enum NotificationKind { alert, order, reminder, sync, review }

class AppNotification {
  AppNotification({
    required this.kind,
    required this.title,
    required this.body,
    required this.time,
    required this.isToday,
    this.targetId,
    this.isRead = false,
  });

  final NotificationKind kind;
  final String title;
  final String body;
  final String time;
  final bool isToday;

  /// Equipment id (alerts) or order code (orders) to open when tapped.
  final String? targetId;
  bool isRead;
}
