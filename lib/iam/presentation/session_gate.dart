import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/presentation/home_shell.dart';
import '../application/auth_service.dart';
import 'sign_in_page.dart';

/// First screen: tries to restore the stored session (refresh token) and goes
/// to the orders or to the sign-in screen.
class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late final Future<bool> _restore = AuthService.instance.restoreSession();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _restore,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const _Splash();
        return snapshot.data == true ? const HomeShell() : const SignInPage();
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDeep,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SvgPicture.asset('assets/images/logo.svg', height: 96),
          const SizedBox(height: 24),
          const CircularProgressIndicator(color: Colors.white),
        ]),
      ),
    );
  }
}
