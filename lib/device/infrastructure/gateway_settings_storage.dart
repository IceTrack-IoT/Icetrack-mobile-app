import 'package:shared_preferences/shared_preferences.dart';

/// Remembers, on the phone, the gateway address of each site and the device of
/// each unit, so the technician types them only once.
class GatewaySettingsStorage {
  String _urlKey(int siteId) => 'icetrack.gateway_url.$siteId';
  String _deviceKey(int equipmentId) => 'icetrack.gateway_device.$equipmentId';

  Future<String?> gatewayUrl(int siteId) async => (await SharedPreferences.getInstance()).getString(_urlKey(siteId));

  Future<String?> deviceUid(int equipmentId) async =>
      (await SharedPreferences.getInstance()).getString(_deviceKey(equipmentId));

  Future<void> save({required int siteId, required int equipmentId, required String url, required String deviceUid}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlKey(siteId), url);
    await prefs.setString(_deviceKey(equipmentId), deviceUid);
  }
}
