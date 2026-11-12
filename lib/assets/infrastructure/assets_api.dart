import '../../shared/infrastructure/api_client.dart';
import 'resources/equipment_resource.dart';
import 'resources/site_resource.dart';

/// REST calls of the Assets bounded context readable by the technician
/// (only for units and sites of an active assignment; anything else is 404).
class AssetsApi {
  AssetsApi([ApiClient? client]) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<EquipmentResource> getEquipment(int equipmentId) async =>
      EquipmentResource.fromJson(await _client.get('/assets/equipments/$equipmentId') as Map<String, dynamic>);

  Future<SiteResource> getSite(int siteId) async =>
      SiteResource.fromJson(await _client.get('/assets/sites/$siteId') as Map<String, dynamic>);
}
