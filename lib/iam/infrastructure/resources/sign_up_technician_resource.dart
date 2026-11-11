/// Request body of `POST /authentication/sign-up/technician` (US-01).
/// The role is implied by the path; the response has no tokens, so the app signs in afterwards.
class SignUpTechnicianResource {
  const SignUpTechnicianResource({
    required this.username,
    required this.password,
    required this.email,
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

  final String username;
  final String password;
  final String email;
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
        'username': username,
        'password': password,
        'email': email,
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
