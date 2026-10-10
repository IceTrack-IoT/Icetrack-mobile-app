import '../../monitoring/domain/equipment.dart';
import '../../notifications/domain/app_notification.dart';
import '../../service_requests/domain/service_order.dart';

/// Mock data used while the RESTful API integration (TS-06) is pending.
class MockData {
  MockData._();

  static List<ServiceOrder> orders() => [
        ServiceOrder(
          code: 'OS-1042',
          equipmentId: 'FH-02',
          equipmentName: 'Congeladora horizontal FH-02',
          serviceType: 'Mantenimiento correctivo',
          siteName: 'Heladería Polar · Miraflores',
          address: 'Av. Larco 345, Miraflores',
          scheduledAt: '10:30 a. m.',
          priority: OrderPriority.high,
          status: OrderStatus.pending,
          requestedBy: 'Lucía Torres',
          contactPhone: '987 654 321',
          reportedIssue:
              'El equipo no baja de −12 °C desde la madrugada. El compresor se escucha encendido de forma continua.',
        ),
        ServiceOrder(
          code: 'OS-1038',
          equipmentId: 'VT-05',
          equipmentName: 'Vitrina exhibidora VT-05',
          serviceType: 'Mantenimiento preventivo',
          siteName: 'Helados Andina · San Isidro',
          address: 'Calle Las Begonias 520, San Isidro',
          scheduledAt: '2:00 p. m.',
          priority: OrderPriority.medium,
          status: OrderStatus.accepted,
          requestedBy: 'Marco Salas',
          contactPhone: '986 112 450',
          reportedIssue: 'Revisión preventiva trimestral y limpieza de condensador.',
        ),
        ServiceOrder(
          code: 'OS-1031',
          equipmentId: 'CF-01',
          equipmentName: 'Cámara de frío CF-01',
          serviceType: 'Mantenimiento preventivo',
          siteName: 'Heladería Polar · Surco',
          address: 'Av. Primavera 1180, Surco',
          scheduledAt: '4:30 p. m.',
          priority: OrderPriority.low,
          status: OrderStatus.inProgress,
          requestedBy: 'Lucía Torres',
          contactPhone: '987 654 321',
          reportedIssue: 'Cambio programado de burletes de puerta.',
        ),
      ];

  static Map<String, Equipment> equipment() => {
        'FH-02': const Equipment(
          id: 'FH-02',
          name: 'Congeladora horizontal FH-02',
          model: 'Frigo FH-450',
          siteName: 'Heladería Polar · Miraflores',
          temperature: -12.4,
          threshold: -18,
          powerKw: 1.8,
          energyKwh: 14.2,
          isDoorOpen: false,
          health: EquipmentHealth.critical,
          lastReading: '09:41:08',
          readings: [-20.5, -20.8, -20.3, -20.6, -20.1, -19.8, -18.9, -17.2, -15.6, -14.1, -13.2, -12.4],
          history: [
            PastIntervention(date: '12 sep 2026', type: 'Preventivo', summary: 'Limpieza de condensador y revisión de carga de gas'),
            PastIntervention(date: '28 jul 2026', type: 'Correctivo', summary: 'Cambio del ventilador del evaporador'),
          ],
        ),
        'VT-05': const Equipment(
          id: 'VT-05',
          name: 'Vitrina exhibidora VT-05',
          model: 'Coldline V-120',
          siteName: 'Helados Andina · San Isidro',
          temperature: -16.9,
          threshold: -18,
          powerKw: 1.2,
          energyKwh: 9.6,
          isDoorOpen: true,
          health: EquipmentHealth.warning,
          lastReading: '09:40:52',
          readings: [-19.8, -19.6, -19.9, -19.7, -19.5, -19.2, -18.8, -18.1, -17.6, -17.2, -17.0, -16.9],
          history: [
            PastIntervention(date: '03 ago 2026', type: 'Preventivo', summary: 'Ajuste de termostato y limpieza general'),
          ],
        ),
        'CF-01': const Equipment(
          id: 'CF-01',
          name: 'Cámara de frío CF-01',
          model: 'Polar CR-900',
          siteName: 'Heladería Polar · Surco',
          temperature: -21.0,
          threshold: -18,
          powerKw: 2.6,
          energyKwh: 21.4,
          isDoorOpen: false,
          health: EquipmentHealth.normal,
          lastReading: '09:41:02',
          readings: [-21.2, -21.0, -21.3, -21.1, -20.9, -21.0, -21.2, -21.1, -21.0, -20.8, -21.0, -21.0],
          history: [
            PastIntervention(date: '15 jun 2026', type: 'Preventivo', summary: 'Revisión de compresor y burletes'),
          ],
        ),
        'CF-03': const Equipment(
          id: 'CF-03',
          name: 'Cámara de frío CF-03',
          model: 'Polar CR-600',
          siteName: 'Heladería Polar · Surco',
          temperature: null,
          threshold: -18,
          powerKw: 0,
          energyKwh: 0,
          isDoorOpen: false,
          health: EquipmentHealth.offline,
          lastReading: '08:20:00',
          readings: [-20.4, -20.6, -20.5, -20.3],
          history: [],
        ),
      };

  static List<EquipmentAlert> alerts() => const [
        EquipmentAlert(equipmentId: 'FH-02', health: EquipmentHealth.critical, detail: 'umbral −18 °C · hace 29 min'),
        EquipmentAlert(equipmentId: 'VT-05', health: EquipmentHealth.warning, detail: 'puerta abierta 6 min'),
        EquipmentAlert(equipmentId: 'CF-03', health: EquipmentHealth.offline, detail: 'sin lecturas desde 08:20'),
      ];

  static List<AppNotification> notifications() => [
        AppNotification(kind: NotificationKind.alert, title: 'Alerta crítica · FH-02', body: '−12.4 °C en Heladería Polar – Miraflores', time: '09:12', isToday: true, targetId: 'FH-02'),
        AppNotification(kind: NotificationKind.order, title: 'Nueva orden asignada · OS-1042', body: 'Congeladora FH-02 · Heladería Polar', time: '08:57', isToday: true, targetId: 'OS-1042'),
        AppNotification(kind: NotificationKind.reminder, title: 'Recordatorio de mantenimiento', body: 'Cámara CF-01 vence su preventivo en 3 días', time: '08:00', isToday: true),
        AppNotification(kind: NotificationKind.sync, title: 'Intervención sincronizada', body: 'OS-1029 se envió al recuperar la conexión', time: '18:40', isToday: false, isRead: true),
        AppNotification(kind: NotificationKind.review, title: 'Servicio evaluado', body: 'La propietaria calificó OS-1027 con 5/5', time: '16:05', isToday: false, isRead: true),
      ];
}
