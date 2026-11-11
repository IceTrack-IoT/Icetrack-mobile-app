/// Account of the signed-in user (IAM bounded context).
/// [id] is the USER ACCOUNT id, not the technician profile id.
class AuthenticatedUser {
  const AuthenticatedUser({
    required this.id,
    required this.username,
    required this.role,
    required this.provider,
    this.email,
  });

  static const String technicianRole = 'TECHNICIAN_ROLE';

  final int id;
  final String username;
  final String role;
  final String provider;
  final String? email;

  bool get isTechnician => role == technicianRole;
  bool get signedInWithGoogle => provider == 'GOOGLE';
}
