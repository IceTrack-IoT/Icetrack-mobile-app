enum NotificationType {
  temperatureExcursion,
  deviceOffline,
  sensorFailure,
  serviceRequestUpdate,
  maintenanceWindow,
  other,
}

enum NotificationSeverity { critical, warning, info }

/// Notice addressed to the technician (Notifications bounded context).
/// The backend stores a template key and its values, so the app can show it in the user's language.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.severity,
    required this.messageKey,
    required this.params,
    required this.fallbackMessage,
    required this.isRead,
    required this.createdAt,
    this.equipmentId,
    this.serviceRequestId,
    this.sourceAlertId,
  });

  final int id;
  final NotificationType type;
  final NotificationSeverity severity;
  final String messageKey;
  final Map<String, Object?> params;
  final String fallbackMessage;
  final bool isRead;
  final DateTime createdAt;
  final int? equipmentId;
  final int? serviceRequestId;
  final int? sourceAlertId;

  bool get isAlert =>
      type == NotificationType.temperatureExcursion ||
      type == NotificationType.deviceOffline ||
      type == NotificationType.sensorFailure;

  AppNotification markedRead() => AppNotification(
        id: id,
        type: type,
        severity: severity,
        messageKey: messageKey,
        params: params,
        fallbackMessage: fallbackMessage,
        isRead: true,
        createdAt: createdAt,
        equipmentId: equipmentId,
        serviceRequestId: serviceRequestId,
        sourceAlertId: sourceAlertId,
      );
}
