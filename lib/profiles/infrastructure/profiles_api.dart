import '../../shared/infrastructure/api_client.dart';
import 'resources/technician_profile_resource.dart';

/// REST calls of the Profiles bounded context used by the technician app.
class ProfilesApi {
  ProfilesApi([ApiClient? client]) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<TechnicianProfileResource> getTechnicianByUserId(int userId) async {
    final json = await _client.get('/profiles/technicians/user/$userId');
    return TechnicianProfileResource.fromJson(json as Map<String, dynamic>);
  }
}
