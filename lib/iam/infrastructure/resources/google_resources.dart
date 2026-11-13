/// Body of `POST /authentication/google/verify`.
class SignInWithGoogleResource {
  const SignInWithGoogleResource({required this.idToken, required this.channel});

  final String idToken;
  final String channel;

  Map<String, dynamic> toJson() => {'id_token': idToken, 'channel': channel};
}

/// Body of `POST /authentication/google/complete-registration/technician`.
/// Name and email are taken by the backend from the Google token.
class CompleteGoogleTechnicianRegistrationResource {
  const CompleteGoogleTechnicianRegistrationResource({
    required this.idToken,
    required this.username,
    required this.phone,
    required this.street,
    this.number,
    required this.city,
    required this.postalCode,
    required this.country,
    required this.speciality,
    required this.certificationNumber,
  });

  final String idToken;
  final String username;
  final String phone;
  final String street;
  final String? number;
  final String city;
  final String postalCode;
  final String country;
  final String speciality;
  final String certificationNumber;

  Map<String, dynamic> toJson() => {
        'id_token': idToken,
        'username': username,
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

/// Body of `POST /authentication/google/link`: links Google to an account created with a password.
class LinkGoogleAccountResource {
  const LinkGoogleAccountResource({required this.idToken, required this.password, required this.channel});

  final String idToken;
  final String password;
  final String channel;

  Map<String, dynamic> toJson() => {'id_token': idToken, 'password': password, 'channel': channel};
}
