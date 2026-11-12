import '../../shared/infrastructure/api_client.dart';
import '../../shared/infrastructure/uuid.dart';
import 'resources/register_intervention_resource.dart';
import 'resources/service_request_resource.dart';

/// REST calls of the Service Request bounded context used by the technician.
class ServiceRequestsApi {
  ServiceRequestsApi([ApiClient? client]) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  /// Requests assigned to the caller, newest first (US-30).
  Future<PagedServiceRequestResource> listAssigned({
    String status = 'PENDING,ACCEPTED,IN_PROGRESS,COMPLETED',
    int page = 0,
    int size = 50,
  }) async {
    final json = await _client.get('/service-requests', query: {
      'assigned_to': 'me',
      'status': status,
      'page': '$page',
      'size': '$size',
    });
    return PagedServiceRequestResource.fromJson(json as Map<String, dynamic>);
  }

  Future<ServiceRequestResource> getById(int id) async =>
      ServiceRequestResource.fromJson(await _client.get('/service-requests/$id') as Map<String, dynamic>);

  /// PENDING -> ACCEPTED. The response carries `edge_grant.token` (only here).
  Future<ServiceRequestResource> accept(int id) async =>
      ServiceRequestResource.fromJson(await _client.put('/service-requests/$id/accept') as Map<String, dynamic>);

  /// The request returns to the owner unassigned.
  Future<ServiceRequestResource> reject(int id, String reason) async => ServiceRequestResource.fromJson(
      await _client.put('/service-requests/$id/reject', body: {'reason': reason}) as Map<String, dynamic>);

  /// ACCEPTED -> IN_PROGRESS, with the device instant (US-33).
  Future<ServiceRequestResource> start(int id, DateTime startedAt) async => ServiceRequestResource.fromJson(
      await _client.put('/service-requests/$id/start', body: {'started_at': isoUtc(startedAt)})
          as Map<String, dynamic>);

  /// IN_PROGRESS -> COMPLETED. Idempotent by `client_generated_id` (201 first time, 200 on replay).
  Future<void> registerIntervention(RegisterInterventionResource resource) async {
    await _client.post('/interventions', body: resource.toJson());
  }

  /// Interventions already registered on a unit (newest data for the equipment history).
  Future<List<InterventionResource>> interventionsOfEquipment(int equipmentId) async {
    final json = await _client.get('/assets/equipments/$equipmentId/interventions');
    return (json as List<dynamic>).map((e) => InterventionResource.fromJson(e as Map<String, dynamic>)).toList();
  }
}
