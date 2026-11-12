/// Request body of `PUT /profiles/technicians/{technicianId}` (US-07).
/// The email belongs to the account and cannot be changed here.
class UpdateTechnicianResource {
  const UpdateTechnicianResource({
    required this.fullName,
    required this.phone,
    required this.street,
    this.number,
    required this.city,
    required this.postalCode,
    required this.country,
    required this.speciality,
    required this.certificationNumber,
  });

  final String fullName;
  final String phone;
  final String street;
  final String? number;
  final String city;
  final String postalCode;
  final String country;
  final String speciality;
  final String certificationNumber;

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'phone': phone,
        'street': street,
        if (number != null && number!.isNotEmpty) 'number': number,
        'city': city,
        'postal_code': postalCode,
        'country': country,
        'speciality': speciality,
        'certification_number': certificationNumber,
      };
}
