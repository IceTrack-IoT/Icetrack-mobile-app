import '../../shared/infrastructure/api_client.dart';
import 'resources/technician_profile_resource.dart';
import 'resources/update_technician_resource.dart';

/// REST calls of the Profiles bounded context used by the technician app.
class ProfilesApi {
  ProfilesApi([ApiClient? client]) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<TechnicianProfileResource> getTechnicianByUserId(int userId) async {
    final json = await _client.get('/profiles/technicians/user/$userId');
    return TechnicianProfileResource.fromJson(json as Map<String, dynamic>);
  }

  /// Only the caller's own profile can be updated (otherwise 403).
  Future<TechnicianProfileResource> updateTechnician(int technicianId, UpdateTechnicianResource resource) async {
    final json = await _client.put('/profiles/technicians/$technicianId', body: resource.toJson());
    return TechnicianProfileResource.fromJson(json as Map<String, dynamic>);
  }
}
