import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'iam/application/auth_service.dart';
import 'iam/presentation/session_gate.dart';
import 'iam/presentation/sign_in_page.dart';
import 'notifications/presentation/push_presenter.dart';
import 'shared/infrastructure/api_client.dart';
import 'shared/presentation/app_navigator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  ApiClient.instance.onSessionExpired = _onSessionExpired;
  attachPushPresentation();
  runApp(const IceTrackApp());
}

/// The refresh token could not be renewed: discard the session and ask to sign in again.
void _onSessionExpired() {
  AuthService.instance.clearLocalSession();
  appNavigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const SignInPage(sessionExpired: true)),
    (_) => false,
  );
}

class IceTrackApp extends StatelessWidget {
  const IceTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IceTrack',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appMessengerKey,
      theme: AppTheme.light(),
      home: const SessionGate(),
    );
  }
}
