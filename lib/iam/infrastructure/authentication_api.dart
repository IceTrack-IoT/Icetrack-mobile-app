import '../../shared/infrastructure/api_client.dart';
import 'resources/authenticated_user_resource.dart';
import 'resources/google_resources.dart';
import 'resources/sign_in_resource.dart';
import 'resources/sign_up_technician_resource.dart';

/// REST calls of the IAM bounded context (`/api/v1/authentication/**`).
class AuthenticationApi {
  AuthenticationApi([ApiClient? client]) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<AuthenticatedUserResource> signInLocal(SignInResource resource) async {
    final json = await _client.post('/authentication/sign-in/local', body: resource.toJson(), authenticated: false);
    return AuthenticatedUserResource.fromJson(json as Map<String, dynamic>);
  }

  /// Answers `201 UserResource` without tokens.
  Future<void> signUpTechnician(SignUpTechnicianResource resource) async {
    await _client.post('/authentication/sign-up/technician', body: resource.toJson(), authenticated: false);
  }

  Future<CurrentUserResource> me() async {
    final json = await _client.get('/authentication/me');
    return CurrentUserResource.fromJson(json as Map<String, dynamic>);
  }

  /// Revokes the refresh token. Idempotent (`204`).
  Future<void> logout(String refreshToken) async {
    await _client.post('/authentication/logout', body: {'refresh_token': refreshToken}, authenticated: false);
  }

  /// 200 when the Google account is registered; 404 GOOGLE_ACCOUNT_NOT_FOUND asks for the
  /// registration form; 409 ACCOUNT_LINK_REQUIRED asks for the password of the existing account.
  Future<AuthenticatedUserResource> googleVerify(SignInWithGoogleResource resource) async {
    final json = await _client.post('/authentication/google/verify', body: resource.toJson(), authenticated: false);
    return AuthenticatedUserResource.fromJson(json as Map<String, dynamic>);
  }

  Future<AuthenticatedUserResource> googleCompleteTechnicianRegistration(
      CompleteGoogleTechnicianRegistrationResource resource) async {
    final json = await _client.post('/authentication/google/complete-registration/technician',
        body: resource.toJson(), authenticated: false);
    return AuthenticatedUserResource.fromJson(json as Map<String, dynamic>);
  }

  Future<AuthenticatedUserResource> googleLink(LinkGoogleAccountResource resource) async {
    final json = await _client.post('/authentication/google/link', body: resource.toJson(), authenticated: false);
    return AuthenticatedUserResource.fromJson(json as Map<String, dynamic>);
  }
}
