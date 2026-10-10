import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/presentation/home_shell.dart';
import 'sign_up_page.dart';

/// Screen 01 · Sign in (US-46, US-02, US-34, US-23).
class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  void _enter(BuildContext context) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
  }

  @override
  Widget build(BuildContext context) {
    return Watch(builder: (context) {
      final text = Theme.of(context).textTheme;
      return Scaffold(
        backgroundColor: AppColors.primaryDeep,
        body: SafeArea(
          bottom: false,
          child: Column(children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 0), child: const LanguageDropdown()),
            ),
            const SizedBox(height: 24),
            SvgPicture.asset('assets/images/logo.svg', height: 96),
            const SizedBox(height: 12),
            Text('IceTrack', style: text.displaySmall?.copyWith(color: Colors.white)),
            const SizedBox(height: 8),
            SizedBox(
              width: 260,
              child: Text(tr('tagline'),
                  textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: AppColors.primaryLight)),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(tr('signInTitle'), style: text.headlineSmall),
                    const SizedBox(height: 4),
                    Text(tr('signInSubtitle'), style: text.bodyMedium?.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 20),
                    GoogleButton(label: tr('continueGoogle'), onPressed: () => _enter(context)),
                    const SizedBox(height: 16),
                    Row(children: [
                      const Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(tr('orEmail'), style: text.bodySmall?.copyWith(color: AppColors.textSubtle)),
                      ),
                      const Expanded(child: Divider(color: AppColors.border)),
                    ]),
                    const SizedBox(height: 16),
                    FieldLabel(tr('email')),
                    const TextField(
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(prefixIcon: Icon(Icons.mail_outline), hintText: 'carlos.ramirez@frioservice.pe'),
                    ),
                    const SizedBox(height: 16),
                    FieldLabel(tr('password')),
                    const TextField(
                      obscureText: true,
                      decoration: InputDecoration(prefixIcon: Icon(Icons.lock_outline), suffixIcon: Icon(Icons.visibility_outlined)),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(onPressed: () => _enter(context), child: Text(tr('signIn'))),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('${tr('newTechnician')} ', style: text.bodyMedium?.copyWith(color: AppColors.textMuted)),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignUpPage())),
                        child: Text(tr('createAccount'),
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      );
    });
  }
}

class LanguageDropdown extends StatelessWidget {
  const LanguageDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        border: Border.all(color: Colors.white.withOpacity(0.28)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: app.languageCode,
          dropdownColor: AppColors.primaryDark,
          iconEnabledColor: Colors.white,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          items: const [
            DropdownMenuItem(value: 'es', child: Text('🌐  Español')),
            DropdownMenuItem(value: 'en', child: Text('🌐  English')),
          ],
          onChanged: (value) {
            if (value != null) app.setLanguage(value);
          },
        ),
      ),
    );
  }
}

class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(foregroundColor: AppColors.textMain),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4285F4)),
          child: const Text('G', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
        const SizedBox(width: 10),
        Text(label),
      ]),
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textMain)),
    );
  }
}
