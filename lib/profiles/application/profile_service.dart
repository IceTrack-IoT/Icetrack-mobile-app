import '../../iam/application/auth_service.dart';
import '../domain/model/street_address.dart';
import '../domain/model/technician_profile.dart';
import '../infrastructure/assemblers/technician_profile_assembler.dart';
import '../infrastructure/profiles_api.dart';
import '../infrastructure/resources/update_technician_resource.dart';

/// Application service of the Profiles context: update of the professional profile (US-07).
class ProfileService {
  ProfileService._();

  static final ProfileService instance = ProfileService._();

  final ProfilesApi _api = ProfilesApi();

  Future<TechnicianProfile> updateProfile({
    required TechnicianProfile current,
    required String fullName,
    required String phone,
    required StreetAddress address,
    required String speciality,
    required String certificationNumber,
  }) async {
    final resource = await _api.updateTechnician(
      current.id,
      UpdateTechnicianResource(
        fullName: fullName,
        phone: phone,
        street: address.street,
        number: address.number,
        city: address.city,
        postalCode: address.postalCode,
        country: address.country,
        speciality: speciality,
        certificationNumber: certificationNumber,
      ),
    );
    final updated = TechnicianProfileAssembler.toEntity(resource);
    AuthService.instance.replaceProfile(updated);
    return updated;
  }
}
