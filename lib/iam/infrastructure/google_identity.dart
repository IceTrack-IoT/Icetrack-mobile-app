import 'package:google_sign_in/google_sign_in.dart';

import '../../shared/infrastructure/api_config.dart';

/// Google account chosen on the phone, with the ID token the backend validates.
class GoogleIdentity {
  const GoogleIdentity({required this.idToken, required this.email, this.displayName});

  final String idToken;
  final String email;
  final String? displayName;
}

/// Native Google sign-in on Android (Credential Manager). The `serverClientId` must be
/// the same OAuth client the backend has as `GOOGLE_CLIENT_ID`, so the ID token is
/// issued for the backend; the Android client (package + SHA-1) lives in that same project.
class GoogleIdentityProvider {
  final GoogleSignIn _signIn = GoogleSignIn.instance;
  Future<void>? _initialization;

  Future<void> _ensureInitialized() =>
      _initialization ??= _signIn.initialize(serverClientId: ApiConfig.googleServerClientId);

  /// Returns null when the technician closes the account picker.
  Future<GoogleIdentity?> signIn() async {
    await _ensureInitialized();
    try {
      final account = await _signIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw const GoogleSignInException(code: GoogleSignInExceptionCode.unknownError);
      return GoogleIdentity(idToken: idToken, email: account.email, displayName: account.displayName);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    await _signIn.signOut();
  }
}
