/// `NotificationResource`.
class NotificationResource {
  const NotificationResource({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    required this.messageKey,
    required this.messageParams,
    required this.isRead,
    required this.createdAt,
    this.equipmentId,
    this.serviceRequestId,
    this.sourceAlertId,
  });

  factory NotificationResource.fromJson(Map<String, dynamic> json) => NotificationResource(
        id: (json['id'] as num).toInt(),
        type: json['type'] as String? ?? '',
        severity: json['severity'] as String? ?? 'INFO',
        message: json['message'] as String? ?? '',
        messageKey: json['message_key'] as String? ?? 'notification.untemplated',
        messageParams: Map<String, Object?>.from(json['message_params'] as Map? ?? const {}),
        isRead: json['is_read'] as bool? ?? false,
        createdAt: json['created_at'] as String?,
        equipmentId: (json['equipment_id'] as num?)?.toInt(),
        serviceRequestId: (json['service_request_id'] as num?)?.toInt(),
        sourceAlertId: (json['source_alert_id'] as num?)?.toInt(),
      );

  final int id;
  final String type;
  final String severity;
  final String message;
  final String messageKey;
  final Map<String, Object?> messageParams;
  final bool isRead;
  final String? createdAt;
  final int? equipmentId;
  final int? serviceRequestId;
  final int? sourceAlertId;
}

/// `PagedNotificationResource`: unlike the other lists, the items come under `items`.
class PagedNotificationResource {
  const PagedNotificationResource({required this.items, required this.totalElements});

  factory PagedNotificationResource.fromJson(Map<String, dynamic> json) => PagedNotificationResource(
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((e) => NotificationResource.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalElements: (json['total_elements'] as num?)?.toInt() ?? 0,
      );

  final List<NotificationResource> items;
  final int totalElements;
}

/// Body of `PUT /notifications/device-tokens`.
class RegisterDeviceTokenResource {
  const RegisterDeviceTokenResource({required this.token, required this.platform});

  final String token;

  /// ANDROID, IOS or WEB.
  final String platform;

  Map<String, dynamic> toJson() => {'token': token, 'platform': platform};
}
