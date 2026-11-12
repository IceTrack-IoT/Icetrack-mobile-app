import '../../../shared/infrastructure/uuid.dart';
import '../../domain/model/alert.dart';
import '../../domain/model/telemetry_point.dart';
import '../resources/monitoring_resources.dart';

class MonitoringAssembler {
  MonitoringAssembler._();

  static Alert toAlert(AlertResource r) => Alert(
        id: r.id,
        equipmentId: r.equipmentId,
        type: switch (r.type) {
          'TEMPERATURE_EXCURSION' => AlertType.temperatureExcursion,
          'DEVICE_OFFLINE' => AlertType.deviceOffline,
          _ => AlertType.other,
        },
        severity: switch (r.severity) {
          'CRITICAL' => AlertSeverity.critical,
          'WARNING' => AlertSeverity.warning,
          _ => AlertSeverity.info,
        },
        status: r.status,
        triggeringTemperature: r.triggeringTemperature,
        peakTemperature: r.peakTemperature,
        openedAt: parseInstant(r.openedAt),
      );

  /// Buckets without an average temperature are skipped (nothing to draw).
  static List<TelemetryPoint> toPoints(List<TelemetryBucketResource> buckets) => [
        for (final b in buckets)
          if (b.avgTemperature != null && parseInstant(b.bucketStart) != null)
            TelemetryPoint(
              start: parseInstant(b.bucketStart)!,
              avgTemperature: b.avgTemperature!,
              minTemperature: b.minTemperature,
              maxTemperature: b.maxTemperature,
              avgHumidity: b.avgHumidity,
              doorOpenSeconds: b.doorOpenSeconds ?? 0,
              underMaintenance: b.underMaintenance,
            ),
      ];
}
