import '../../notifications/domain/app_notification.dart';

/// Mock notifications, used until the notification inbox is connected (step 5).
/// Orders, equipment, telemetry and alerts already come from the backend.
class MockData {
  MockData._();

  static List<AppNotification> notifications() => [
        AppNotification(kind: NotificationKind.alert, title: 'Alerta crítica · FH-02', body: '−12.4 °C en Heladería Polar – Miraflores', time: '09:12', isToday: true, targetId: 'FH-02'),
        AppNotification(kind: NotificationKind.order, title: 'Nueva orden asignada · OS-1042', body: 'Congeladora FH-02 · Heladería Polar', time: '08:57', isToday: true, targetId: 'OS-1042'),
        AppNotification(kind: NotificationKind.reminder, title: 'Recordatorio de mantenimiento', body: 'Cámara CF-01 vence su preventivo en 3 días', time: '08:00', isToday: true),
        AppNotification(kind: NotificationKind.sync, title: 'Intervención sincronizada', body: 'OS-1029 se envió al recuperar la conexión', time: '18:40', isToday: false, isRead: true),
        AppNotification(kind: NotificationKind.review, title: 'Servicio evaluado', body: 'La propietaria calificó OS-1027 con 5/5', time: '16:05', isToday: false, isRead: true),
      ];
}
