import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/i18n/app_strings.dart';
import '../../shared/infrastructure/api_exception.dart';
import '../../shared/presentation/error_text.dart';
import '../../shared/presentation/home_shell.dart';
import '../application/auth_service.dart';
import 'google_sign_up_page.dart';

/// "Continue with Google" from the sign-in and sign-up screens (US-34, US-46).
/// Returns an error text to show, or null when it finished or was canceled.
Future<String?> continueWithGoogle(BuildContext context) async {
  final navigator = Navigator.of(context);
  try {
    final outcome = await AuthService.instance.signInWithGoogle();
    switch (outcome) {
      case GoogleSignInOutcome.signedIn:
        navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeShell()), (_) => false);
      case GoogleSignInOutcome.needsRegistration:
        navigator.push(MaterialPageRoute(builder: (_) => const GoogleSignUpPage()));
      case GoogleSignInOutcome.needsLink:
        if (!context.mounted) return null;
        final linked = await showDialog<bool>(context: context, builder: (_) => const _LinkGoogleDialog());
        if (linked == true) {
          navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeShell()), (_) => false);
        }
      case GoogleSignInOutcome.canceled:
        break;
    }
    return null;
  } on GoogleSignInException catch (e) {
    return e.code == GoogleSignInExceptionCode.clientConfigurationError ? tr('googleNotConfigured') : tr('googleError');
  } on ApiException catch (e) {
    return e.code == 'INVALID_TOKEN' ? tr('googleError') : errorText(e);
  } catch (e) {
    return errorText(e);
  }
}

/// The Google email already belongs to an account created with a password:
/// asks for that password once to link both sign-in methods.
class _LinkGoogleDialog extends StatefulWidget {
  const _LinkGoogleDialog();

  @override
  State<_LinkGoogleDialog> createState() => _LinkGoogleDialogState();
}

class _LinkGoogleDialogState extends State<_LinkGoogleDialog> {
  final _password = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _link() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await AuthService.instance.linkGoogle(_password.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService.instance.pendingGoogle?.email ?? '';
    return AlertDialog(
      title: Text(tr('linkGoogleTitle')),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tr('linkGoogleBody').replaceFirst('{email}', email)),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: true,
          enabled: !_sending,
          decoration: InputDecoration(labelText: tr('password'), errorText: _error),
          onChanged: (_) => setState(() {}),
        ),
      ]),
      actions: [
        TextButton(onPressed: _sending ? null : () => Navigator.of(context).pop(false), child: Text(tr('cancel'))),
        FilledButton(
          onPressed: _sending || _password.text.isEmpty ? null : _link,
          child: Text(tr('linkGoogleAction')),
        ),
      ],
    );
  }
}
