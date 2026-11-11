/// Professional profile of the technician (Profiles bounded context).
/// [id] is the technician profile id that service requests reference.
class TechnicianProfile {
  const TechnicianProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.speciality,
    required this.certificationNumber,
  });

  final int id;
  final int userId;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String speciality;
  final String certificationNumber;

  String get firstName => fullName.trim().split(' ').first;
}
