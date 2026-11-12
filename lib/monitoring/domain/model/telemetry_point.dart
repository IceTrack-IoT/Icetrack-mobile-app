/// One aggregated point of the temperature history (`TelemetryBucketResource`).
class TelemetryPoint {
  const TelemetryPoint({
    required this.start,
    required this.avgTemperature,
    this.minTemperature,
    this.maxTemperature,
    this.avgHumidity,
    this.doorOpenSeconds = 0,
    this.underMaintenance = false,
  });

  final DateTime start;
  final double avgTemperature;
  final double? minTemperature;
  final double? maxTemperature;
  final double? avgHumidity;
  final int doorOpenSeconds;
  final bool underMaintenance;
}
