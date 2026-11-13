import 'package:flutter/foundation.dart';

import '../../core/state/app_state.dart';
import '../../monitoring/application/monitoring_store.dart';
import '../../notifications/application/notification_store.dart';
import '../../profiles/domain/model/technician_profile.dart';
import '../../profiles/infrastructure/assemblers/technician_profile_assembler.dart';
import '../../profiles/infrastructure/profiles_api.dart';
import '../../service_requests/application/service_request_store.dart';
import '../../shared/infrastructure/api_client.dart';
import '../../shared/infrastructure/api_config.dart';
import '../../shared/infrastructure/api_exception.dart';
import '../../shared/infrastructure/token_storage.dart';
import '../domain/model/authenticated_user.dart';
import '../infrastructure/assemblers/authenticated_user_assembler.dart';
import '../infrastructure/authentication_api.dart';
import '../infrastructure/google_identity.dart';
import '../infrastructure/resources/authenticated_user_resource.dart';
import '../infrastructure/resources/google_resources.dart';
import '../infrastructure/resources/sign_in_resource.dart';
import '../infrastructure/resources/sign_up_technician_resource.dart';

/// Result of "Continue with Google" (US-34, US-46).
enum GoogleSignInOutcome { signedIn, needsRegistration, needsLink, canceled }

/// Application service of the IAM context for the technician app:
/// sign in, sign up, Google sign-in, restore the session on start and sign out (US-01, US-02, US-34).
class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instance = AuthService._();

  final AuthenticationApi _authApi = AuthenticationApi();
  final ProfilesApi _profilesApi = ProfilesApi();
  final TokenStorage _tokens = TokenStorage.instance;
  final GoogleIdentityProvider _google = GoogleIdentityProvider();

  /// Google account waiting for the registration form or for the link password.
  GoogleIdentity? pendingGoogle;

  AuthenticatedUser? user;
  TechnicianProfile? profile;

  bool get isSignedIn => user != null && profile != null;

  Future<void> signIn({required String usernameOrEmail, required String password}) async {
    final resource = await _authApi.signInLocal(SignInResource(
      username: usernameOrEmail.trim(),
      password: password,
      channel: ApiConfig.channel,
    ));
    await _tokens.save(accessToken: resource.token, refreshToken: resource.refreshToken);
    user = AuthenticatedUserAssembler.fromAuthenticatedResource(resource);
    await _loadProfile();
  }

  /// Opens the Google account picker and signs in with the backend.
  Future<GoogleSignInOutcome> signInWithGoogle() async {
    final identity = await _google.signIn();
    if (identity == null) return GoogleSignInOutcome.canceled;
    try {
      await _startSession(await _authApi.googleVerify(
        SignInWithGoogleResource(idToken: identity.idToken, channel: ApiConfig.channel),
      ));
      pendingGoogle = null;
      return GoogleSignInOutcome.signedIn;
    } on ApiException catch (e) {
      if (e.code == 'GOOGLE_ACCOUNT_NOT_FOUND') {
        pendingGoogle = identity;
        return GoogleSignInOutcome.needsRegistration;
      }
      if (e.code == 'ACCOUNT_LINK_REQUIRED') {
        pendingGoogle = identity;
        return GoogleSignInOutcome.needsLink;
      }
      await _google.signOut();
      rethrow;
    }
  }

  /// New Google user: creates the technician account with the form data.
  Future<void> completeGoogleRegistration({
    required String username,
    required String phone,
    required String street,
    String? number,
    required String city,
    required String postalCode,
    required String country,
    required String speciality,
    required String certificationNumber,
  }) async {
    final identity = pendingGoogle!;
    await _startSession(await _authApi.googleCompleteTechnicianRegistration(
      CompleteGoogleTechnicianRegistrationResource(
        idToken: identity.idToken,
        username: username,
        phone: phone,
        street: street,
        number: number,
        city: city,
        postalCode: postalCode,
        country: country,
        speciality: speciality,
        certificationNumber: certificationNumber,
      ),
    ));
    pendingGoogle = null;
  }

  /// The Google email already has an account with a password: links both after checking it.
  Future<void> linkGoogle(String password) async {
    final identity = pendingGoogle!;
    await _startSession(await _authApi.googleLink(
      LinkGoogleAccountResource(idToken: identity.idToken, password: password, channel: ApiConfig.channel),
    ));
    pendingGoogle = null;
  }

  Future<void> _startSession(AuthenticatedUserResource resource) async {
    await _tokens.save(accessToken: resource.token, refreshToken: resource.refreshToken);
    user = AuthenticatedUserAssembler.fromAuthenticatedResource(resource);
    await _loadProfile();
  }

  /// Creates the technician account and then signs in with the same credentials.
  Future<void> signUp(SignUpTechnicianResource resource) async {
    await _authApi.signUpTechnician(resource);
    await signIn(usernameOrEmail: resource.username, password: resource.password);
  }

  /// Called on app start: if a refresh token is stored, renew it and reload the user.
  /// Returns false when the technician has to sign in again.
  Future<bool> restoreSession() async {
    if (!await _tokens.hasRefreshToken()) return false;
    try {
      final refreshed = await ApiClient.instance.refreshSession();
      if (!refreshed) {
        await clearLocalSession();
        return false;
      }
      user = AuthenticatedUserAssembler.fromCurrentUserResource(await _authApi.me());
      if (!user!.isTechnician) {
        await clearLocalSession();
        return false;
      }
      await _loadProfile();
      return true;
    } on ApiException {
      // Without connection or with a rejected session we go to the sign-in screen;
      // the refresh token is kept when it was only a network problem.
      user = null;
      profile = null;
      return false;
    }
  }

  Future<void> signOut() async {
    // While the access token is still valid, so this phone stops receiving pushes.
    await NotificationStore.instance.stopPush();
    final refreshToken = await _tokens.readRefreshToken();
    if (refreshToken != null) {
      try {
        await _authApi.logout(refreshToken);
      } on ApiException {
        // Logout is best effort: the local session is discarded anyway.
      }
    }
    try {
      await _google.signOut();
    } catch (_) {
      // Not signed in with Google on this phone.
    }
    await clearLocalSession();
  }

  Future<void> clearLocalSession() async {
    await _tokens.clear();
    user = null;
    profile = null;
    AppState.instance.clearTechnician();
    await ServiceRequestStore.instance.reset();
    MonitoringStore.instance.reset();
    NotificationStore.instance.reset();
    notifyListeners();
  }

  /// Called by the Profiles context after the technician edits the profile (US-07).
  void replaceProfile(TechnicianProfile updated) {
    profile = updated;
    AppState.instance.setTechnician(name: updated.fullName, speciality: updated.speciality);
    notifyListeners();
  }

  Future<void> _loadProfile() async {
    final resource = await _profilesApi.getTechnicianByUserId(user!.id);
    profile = TechnicianProfileAssembler.toEntity(resource);
    AppState.instance.setTechnician(name: profile!.fullName, speciality: profile!.speciality);
    notifyListeners();
  }
}
