/// `AlertResource` (fields the technician app uses).
class AlertResource {
  const AlertResource({
    required this.id,
    required this.equipmentId,
    required this.type,
    required this.severity,
    required this.status,
    this.triggeringTemperature,
    this.peakTemperature,
    this.openedAt,
  });

  factory AlertResource.fromJson(Map<String, dynamic> json) => AlertResource(
        id: (json['id'] as num).toInt(),
        equipmentId: (json['equipment_id'] as num).toInt(),
        type: json['type'] as String? ?? '',
        severity: json['severity'] as String? ?? 'INFO',
        status: json['status'] as String? ?? 'OPEN',
        triggeringTemperature: (json['triggering_temperature'] as num?)?.toDouble(),
        peakTemperature: (json['peak_temperature'] as num?)?.toDouble(),
        openedAt: json['opened_at'] as String?,
      );

  final int id;
  final int equipmentId;
  final String type;
  final String severity;
  final String status;
  final double? triggeringTemperature;
  final double? peakTemperature;
  final String? openedAt;
}

/// `TelemetryBucketResource` (response of the telemetry history with `bucket`).
class TelemetryBucketResource {
  const TelemetryBucketResource({
    required this.bucketStart,
    this.minTemperature,
    this.maxTemperature,
    this.avgTemperature,
    this.avgHumidity,
    this.doorOpenSeconds,
    this.underMaintenance = false,
  });

  factory TelemetryBucketResource.fromJson(Map<String, dynamic> json) => TelemetryBucketResource(
        bucketStart: json['bucket_start'] as String,
        minTemperature: (json['min_temperature'] as num?)?.toDouble(),
        maxTemperature: (json['max_temperature'] as num?)?.toDouble(),
        avgTemperature: (json['avg_temperature'] as num?)?.toDouble(),
        avgHumidity: (json['avg_humidity'] as num?)?.toDouble(),
        doorOpenSeconds: (json['door_open_seconds'] as num?)?.toInt(),
        underMaintenance: json['under_maintenance'] as bool? ?? false,
      );

  final String bucketStart;
  final double? minTemperature;
  final double? maxTemperature;
  final double? avgTemperature;
  final double? avgHumidity;
  final int? doorOpenSeconds;
  final bool underMaintenance;
}
