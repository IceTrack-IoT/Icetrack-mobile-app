/// Response of sign-in, Google exchange and refresh (`AuthenticatedUserResource`).
/// Note: the access token property is `token`, not `access_token`.
class AuthenticatedUserResource {
  const AuthenticatedUserResource({
    required this.id,
    required this.username,
    required this.role,
    required this.provider,
    required this.token,
    required this.refreshToken,
  });

  factory AuthenticatedUserResource.fromJson(Map<String, dynamic> json) => AuthenticatedUserResource(
        id: (json['id'] as num).toInt(),
        username: json['username'] as String? ?? '',
        role: json['role'] as String? ?? '',
        provider: json['provider'] as String? ?? 'LOCAL',
        token: json['token'] as String,
        refreshToken: json['refresh_token'] as String,
      );

  final int id;
  final String username;
  final String role;
  final String provider;
  final String token;
  final String refreshToken;
}

/// Response of `GET /authentication/me` (`CurrentUserResource`).
class CurrentUserResource {
  const CurrentUserResource({
    required this.id,
    required this.username,
    required this.role,
    required this.provider,
    this.email,
  });

  factory CurrentUserResource.fromJson(Map<String, dynamic> json) => CurrentUserResource(
        id: (json['id'] as num).toInt(),
        username: json['username'] as String? ?? '',
        role: json['role'] as String? ?? '',
        provider: json['provider'] as String? ?? 'LOCAL',
        email: json['email'] as String?,
      );

  final int id;
  final String username;
  final String role;
  final String provider;
  final String? email;
}
