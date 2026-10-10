import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/presentation/home_shell.dart';
import 'sign_in_page.dart';

/// Screen 02 · Technician sign up (US-01, US-34).
class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  void _enter(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeShell()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Watch(builder: (context) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('createAccount'))),
        body: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 24), children: [
          Text(tr('signUpIntro'), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 16),
          FieldLabel(tr('fullName')),
          const TextField(decoration: InputDecoration(prefixIcon: Icon(Icons.person_outline))),
          const SizedBox(height: 16),
          FieldLabel(tr('email')),
          const TextField(keyboardType: TextInputType.emailAddress, decoration: InputDecoration(prefixIcon: Icon(Icons.mail_outline))),
          const SizedBox(height: 16),
          FieldLabel(tr('company')),
          const TextField(decoration: InputDecoration(prefixIcon: Icon(Icons.build_outlined))),
          const SizedBox(height: 16),
          FieldLabel(tr('password')),
          TextField(obscureText: true, decoration: InputDecoration(prefixIcon: const Icon(Icons.lock_outline), hintText: tr('passwordHint'))),
          const SizedBox(height: 24),
          FilledButton(onPressed: () => _enter(context), child: Text(tr('createAccount'))),
          const SizedBox(height: 12),
          GoogleButton(label: tr('signUpGoogle'), onPressed: () => _enter(context)),
        ]),
      );
    });
  }
}
