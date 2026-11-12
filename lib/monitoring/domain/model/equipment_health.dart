import '../../../assets/domain/model/equipment.dart';
import 'alert.dart';

/// Visual state of a unit shown in the app (color of badges, chart and alerts).
enum EquipmentHealth { normal, warning, critical, offline }

/// Derives the health from the unit and its open alerts.
EquipmentHealth healthOf(Equipment equipment, List<Alert> openAlerts) {
  if (equipment.isSilent || openAlerts.any((a) => a.type == AlertType.deviceOffline)) {
    return EquipmentHealth.offline;
  }
  if (equipment.isOutOfRange || openAlerts.any((a) => a.severity == AlertSeverity.critical)) {
    return EquipmentHealth.critical;
  }
  if (openAlerts.isNotEmpty) return EquipmentHealth.warning;
  return EquipmentHealth.normal;
}
