import 'package:flutter/foundation.dart';

import '../../core/state/app_state.dart';
import '../../profiles/domain/model/technician_profile.dart';
import '../../profiles/infrastructure/assemblers/technician_profile_assembler.dart';
import '../../profiles/infrastructure/profiles_api.dart';
import '../../shared/infrastructure/api_client.dart';
import '../../shared/infrastructure/api_config.dart';
import '../../shared/infrastructure/api_exception.dart';
import '../../shared/infrastructure/token_storage.dart';
import '../domain/model/authenticated_user.dart';
import '../infrastructure/assemblers/authenticated_user_assembler.dart';
import '../infrastructure/authentication_api.dart';
import '../infrastructure/resources/sign_in_resource.dart';
import '../infrastructure/resources/sign_up_technician_resource.dart';

/// Application service of the IAM context for the technician app:
/// sign in, sign up, restore the session on start and sign out (US-01, US-02).
class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instance = AuthService._();

  final AuthenticationApi _authApi = AuthenticationApi();
  final ProfilesApi _profilesApi = ProfilesApi();
  final TokenStorage _tokens = TokenStorage.instance;

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
    final refreshToken = await _tokens.readRefreshToken();
    if (refreshToken != null) {
      try {
        await _authApi.logout(refreshToken);
      } on ApiException {
        // Logout is best effort: the local session is discarded anyway.
      }
    }
    await clearLocalSession();
  }

  Future<void> clearLocalSession() async {
    await _tokens.clear();
    user = null;
    profile = null;
    AppState.instance.clearTechnician();
    notifyListeners();
  }

  Future<void> _loadProfile() async {
    final resource = await _profilesApi.getTechnicianByUserId(user!.id);
    profile = TechnicianProfileAssembler.toEntity(resource);
    AppState.instance.setTechnician(name: profile!.fullName, speciality: profile!.speciality);
    notifyListeners();
  }
}
