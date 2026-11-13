import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/presentation/error_text.dart';
import '../../shared/presentation/home_shell.dart';
import '../application/auth_service.dart';
import '../infrastructure/resources/sign_up_technician_resource.dart';
import 'google_flow.dart';
import 'sign_in_page.dart';

/// Screen 02: Technician sign up (US-01, US-34).
/// Creates the account with `POST /authentication/sign-up/technician` and signs in right after.
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController(text: '+51 ');
  final _street = TextEditingController();
  final _number = TextEditingController();
  final _city = TextEditingController(text: 'Lima');
  final _postalCode = TextEditingController();
  final _country = TextEditingController(text: 'Perú');
  final _speciality = TextEditingController();
  final _certification = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  static final _usernamePattern = RegExp(r'^[A-Za-z0-9._]{4,30}$');
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _passwordPattern = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9]).{8,64}$');
  static final _certificationPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9./-]{2,49}$');

  @override
  void dispose() {
    for (final c in [
      _fullName, _username, _email, _phone, _street, _number, _city, _postalCode, _country, _speciality,
      _certification, _password,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) => (value == null || value.trim().isEmpty) ? tr('fieldRequired') : null;

  String? _match(String? value, RegExp pattern, String errorKey) {
    final empty = _required(value);
    if (empty != null) return empty;
    return pattern.hasMatch(value!.trim()) ? null : tr(errorKey);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.signUp(SignUpTechnicianResource(
        username: _username.text.trim(),
        password: _password.text,
        email: _email.text.trim(),
        fullName: _fullName.text.trim(),
        phone: _phone.text.trim(),
        street: _street.text.trim(),
        number: _number.text.trim(),
        city: _city.text.trim(),
        postalCode: _postalCode.text.trim(),
        country: _country.text.trim(),
        speciality: _speciality.text.trim(),
        certificationNumber: _certification.text.trim(),
      ));
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeShell()), (_) => false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await continueWithGoogle(context);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
    });
  }

  Widget _field(
    String labelKey,
    TextEditingController controller,
    IconData icon, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    String? hint,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FieldLabel(tr(labelKey)),
        TextFormField(
          controller: controller,
          enabled: !_loading,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscure,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(prefixIcon: Icon(icon), hintText: hint, suffixIcon: suffix),
        ),
      ]),
    );
  }

  Widget _section(String key) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        child: Text(tr(key), style: Theme.of(context).textTheme.titleMedium),
      );

  @override
  Widget build(BuildContext context) {
    return Watch(builder: (context) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('createAccount'))),
        body: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 24), children: [
            Text(tr('signUpIntro'), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            _section('sectionAccount'),
            _field('fullName', _fullName, Icons.person_outline, validator: _required),
            _field('username', _username, Icons.alternate_email,
                hint: 'carlos.ramirez', validator: (v) => _match(v, _usernamePattern, 'usernameInvalid')),
            _field('email', _email, Icons.mail_outline,
                keyboardType: TextInputType.emailAddress, validator: (v) => _match(v, _emailPattern, 'emailInvalid')),
            _field('password', _password, Icons.lock_outline,
                obscure: _obscure,
                hint: tr('passwordHint'),
                validator: (v) => _match(v, _passwordPattern, 'passwordInvalid'),
                suffix: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )),
            _section('sectionProfessional'),
            _field('speciality', _speciality, Icons.ac_unit, hint: tr('specialityHint'), validator: _required),
            _field('certificationNumber', _certification, Icons.badge_outlined,
                hint: 'CERT-2024-001', validator: (v) => _match(v, _certificationPattern, 'certificationInvalid')),
            _section('sectionContact'),
            _field('phone', _phone, Icons.phone_outlined, keyboardType: TextInputType.phone, validator: _required),
            _field('street', _street, Icons.signpost_outlined, validator: _required),
            _field('streetNumber', _number, Icons.tag),
            _field('city', _city, Icons.location_city_outlined, validator: _required),
            _field('postalCode', _postalCode, Icons.markunread_mailbox_outlined,
                keyboardType: TextInputType.number, validator: _required),
            _field('country', _country, Icons.public, validator: _required),
            if (_error != null) ...[
              FormMessage(text: _error!),
              const SizedBox(height: 16),
            ],
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(tr('createAccount')),
            ),
            const SizedBox(height: 12),
            GoogleButton(
              label: tr('signUpGoogle'),
              onPressed: _loading ? null : _google,
            ),
          ]),
        ),
      );
    });
  }
}
