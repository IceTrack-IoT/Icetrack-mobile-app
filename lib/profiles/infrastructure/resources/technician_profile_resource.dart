/// Response of `GET /profiles/technicians/user/{userId}` (`TechnicianProfileResource`).
class TechnicianProfileResource {
  const TechnicianProfileResource({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.speciality,
    required this.certificationNumber,
  });

  factory TechnicianProfileResource.fromJson(Map<String, dynamic> json) => TechnicianProfileResource(
        id: (json['id'] as num).toInt(),
        userId: (json['user_id'] as num).toInt(),
        fullName: json['full_name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        address: json['address'] as String? ?? '',
        speciality: json['speciality'] as String? ?? '',
        certificationNumber: json['certification_number'] as String? ?? '',
      );

  final int id;
  final int userId;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String speciality;
  final String certificationNumber;
}
