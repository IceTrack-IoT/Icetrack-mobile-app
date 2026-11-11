import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/presentation/error_text.dart';
import '../../shared/presentation/home_shell.dart';
import '../application/auth_service.dart';
import 'sign_up_page.dart';

/// Screen 01 · Sign in (US-46, US-02, US-34, US-23).
/// Signs in against the backend with `channel: MOBILE` (technicians only).
class SignInPage extends StatefulWidget {
  const SignInPage({super.key, this.sessionExpired = false});

  /// True when the app came here because the session could not be renewed.
  final bool sessionExpired;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_username.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = tr('errorRequiredCredentials'));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.signIn(usernameOrEmail: _username.text, password: _password.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _googleNotReady() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('googleComingSoon'))));
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
            const Align(
              alignment: Alignment.centerRight,
              child: Padding(padding: EdgeInsets.fromLTRB(24, 8, 24, 0), child: LanguageDropdown()),
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
                    if (widget.sessionExpired && _error == null) ...[
                      const SizedBox(height: 16),
                      FormMessage(text: tr('sessionExpiredBody'), isError: false),
                    ],
                    const SizedBox(height: 20),
                    GoogleButton(label: tr('continueGoogle'), onPressed: _loading ? null : _googleNotReady),
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
                    FieldLabel(tr('userOrEmail')),
                    TextField(
                      controller: _username,
                      enabled: !_loading,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person_outline), hintText: 'carlos.ramirez@frioservice.pe'),
                    ),
                    const SizedBox(height: 16),
                    FieldLabel(tr('password')),
                    TextField(
                      controller: _password,
                      enabled: !_loading,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      FormMessage(text: _error!),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(tr('signIn')),
                    ),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('${tr('newTechnician')} ', style: text.bodyMedium?.copyWith(color: AppColors.textMuted)),
                      GestureDetector(
                        onTap: _loading
                            ? null
                            : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignUpPage())),
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
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
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
  final VoidCallback? onPressed;

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

/// Inline error (red) or information (blue) box used by the auth forms.
class FormMessage extends StatelessWidget {
  const FormMessage({super.key, required this.text, this.isError = true});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.danger : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(isError ? Icons.error_outline : Icons.info_outline, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: color))),
      ]),
    );
  }
}
