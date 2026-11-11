import '../../domain/model/technician_profile.dart';
import '../resources/technician_profile_resource.dart';

class TechnicianProfileAssembler {
  TechnicianProfileAssembler._();

  static TechnicianProfile toEntity(TechnicianProfileResource resource) => TechnicianProfile(
        id: resource.id,
        userId: resource.userId,
        fullName: resource.fullName,
        email: resource.email,
        phone: resource.phone,
        address: resource.address,
        speciality: resource.speciality,
        certificationNumber: resource.certificationNumber,
      );
}
