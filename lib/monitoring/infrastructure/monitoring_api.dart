import '../../shared/infrastructure/api_client.dart';
import '../../shared/infrastructure/uuid.dart';
import 'resources/monitoring_resources.dart';

/// REST calls of the Monitoring and Alerting context readable by the technician.
class MonitoringApi {
  MonitoringApi([ApiClient? client]) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  /// Temperature history aggregated in buckets chosen by the backend (`bucket=auto`).
  Future<List<TelemetryBucketResource>> telemetry(int equipmentId,
      {required DateTime from, required DateTime to, int maxPoints = 48}) async {
    final json = await _client.get('/telemetry/equipment/$equipmentId', query: {
      'from': isoUtc(from),
      'to': isoUtc(to),
      'bucket': 'auto',
      'max_points': '$maxPoints',
    });
    return (json as List<dynamic>).map((e) => TelemetryBucketResource.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AlertResource>> openAlerts(int equipmentId) async {
    final json = await _client.get('/alerts/equipment/$equipmentId/open');
    return (json as List<dynamic>).map((e) => AlertResource.fromJson(e as Map<String, dynamic>)).toList();
  }
}
