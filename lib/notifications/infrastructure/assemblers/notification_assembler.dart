import '../../../shared/infrastructure/uuid.dart';
import '../../domain/model/app_notification.dart';
import '../resources/notification_resources.dart';

class NotificationAssembler {
  NotificationAssembler._();

  static AppNotification toEntity(NotificationResource r) => AppNotification(
        id: r.id,
        type: typeFromApi(r.type),
        severity: switch (r.severity) {
          'CRITICAL' => NotificationSeverity.critical,
          'WARNING' => NotificationSeverity.warning,
          _ => NotificationSeverity.info,
        },
        messageKey: r.messageKey,
        params: r.messageParams,
        fallbackMessage: r.message,
        isRead: r.isRead,
        createdAt: parseInstant(r.createdAt) ?? DateTime.now(),
        equipmentId: r.equipmentId,
        serviceRequestId: r.serviceRequestId,
        sourceAlertId: r.sourceAlertId,
      );

  static NotificationType typeFromApi(String? value) => switch (value) {
        'TEMPERATURE_EXCURSION' => NotificationType.temperatureExcursion,
        'DEVICE_OFFLINE' => NotificationType.deviceOffline,
        'SENSOR_FAILURE' => NotificationType.sensorFailure,
        'SERVICE_REQUEST_UPDATE' => NotificationType.serviceRequestUpdate,
        'MAINTENANCE_WINDOW' || 'UNLINKED_MAINTENANCE_WINDOW' => NotificationType.maintenanceWindow,
        _ => NotificationType.other,
      };
}
