enum AlertType { temperatureExcursion, deviceOffline, other }

enum AlertSeverity { critical, warning, info }

/// Anomaly raised by the Monitoring and Alerting context (read only for the technician).
class Alert {
  const Alert({
    required this.id,
    required this.equipmentId,
    required this.type,
    required this.severity,
    required this.status,
    this.triggeringTemperature,
    this.peakTemperature,
    this.openedAt,
  });

  final int id;
  final int equipmentId;
  final AlertType type;
  final AlertSeverity severity;

  /// OPEN or ACKNOWLEDGED while active.
  final String status;
  final double? triggeringTemperature;
  final double? peakTemperature;
  final DateTime? openedAt;
}
