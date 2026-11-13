import '../../service_requests/application/service_request_store.dart';
import '../../shared/infrastructure/uuid.dart';
import '../domain/model/gateway_state.dart';
import '../infrastructure/edge_gateway_api.dart';
import '../infrastructure/gateway_settings_storage.dart';
import '../infrastructure/resources/gateway_resources.dart';

/// Application service for the technician's on-site actions on the gateway:
/// local status (US-40), maintenance mode (US-48), buzzer and signal test (US-49).
/// Works on the local network, even when the site has no internet.
class GatewayService {
  GatewayService._();

  static final GatewayService instance = GatewayService._();

  final EdgeGatewayApi _api = EdgeGatewayApi();
  final GatewaySettingsStorage _settings = GatewaySettingsStorage();

  Future<GatewayConnection> savedConnection({required int siteId, required int equipmentId, String? defaultDeviceUid}) async {
    return GatewayConnection(
      baseUrl: await _settings.gatewayUrl(siteId) ?? '',
      deviceUid: await _settings.deviceUid(equipmentId) ?? defaultDeviceUid ?? '',
    );
  }

  /// Normalizes the address the technician typed ("192.168.1.50:5000" -> "http://192.168.1.50:5000").
  String normalizeUrl(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return text;
    return text.startsWith('http://') || text.startsWith('https://') ? text : 'http://$text';
  }

  Future<void> saveConnection({required int siteId, required int equipmentId, required GatewayConnection connection}) =>
      _settings.save(siteId: siteId, equipmentId: equipmentId, url: connection.baseUrl, deviceUid: connection.deviceUid);

  Future<bool> isReachable(GatewayConnection connection) => _api.isReachable(connection.baseUrl);

  Future<GatewayState> setMaintenance(int requestId, GatewayConnection connection, {required bool active}) async {
    final grant = await ServiceRequestStore.instance.edgeGrant(requestId);
    return _toState(await _api.setMaintenance(connection.baseUrl, grant,
        deviceUid: connection.deviceUid, commandUid: uuidV4(), active: active));
  }

  Future<GatewayState> setBuzzerMuted(int requestId, GatewayConnection connection, {required bool muted}) async {
    final grant = await ServiceRequestStore.instance.edgeGrant(requestId);
    return _toState(await _api.setBuzzerMuted(connection.baseUrl, grant,
        deviceUid: connection.deviceUid, commandUid: uuidV4(), muted: muted));
  }

  Future<GatewayState> requestSignalTest(int requestId, GatewayConnection connection) async {
    final grant = await ServiceRequestStore.instance.edgeGrant(requestId);
    return _toState(await _api.requestSignalTest(connection.baseUrl, grant,
        deviceUid: connection.deviceUid, commandUid: uuidV4()));
  }

  /// Asks the backend for a new grant. The gateway learns it on its next sync with the cloud.
  Future<void> renewGrant(int requestId) => ServiceRequestStore.instance.edgeGrant(requestId, renew: true);

  GatewayState _toState(GatewayDirectivesResource r) => GatewayState(
        alarmActive: r.alarmActive,
        buzzerMuted: r.buzzerMuted,
        signalTest: r.signalTest,
        maintenanceActive: r.maintenanceActive,
        maintenanceOrigin: r.maintenanceOrigin,
        maintenanceExpiresAt: parseInstant(r.maintenanceExpiresAt),
      );
}
