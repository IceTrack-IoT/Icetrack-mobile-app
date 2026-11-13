import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../shared/presentation/error_text.dart';
import '../../shared/presentation/home_shell.dart';
import '../application/auth_service.dart';
import 'sign_in_page.dart';

/// Technician registration with a Google account that is not registered yet (US-34).
/// Name and email come from Google; the backend asks for the rest of the profile.
class GoogleSignUpPage extends StatefulWidget {
  const GoogleSignUpPage({super.key});

  @override
  State<GoogleSignUpPage> createState() => _GoogleSignUpPageState();
}

class _GoogleSignUpPageState extends State<GoogleSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _speciality = TextEditingController();
  final _certification = TextEditingController();
  final _phone = TextEditingController(text: '+51 ');
  final _street = TextEditingController();
  final _number = TextEditingController();
  final _city = TextEditingController(text: 'Lima');
  final _postalCode = TextEditingController();
  final _country = TextEditingController(text: 'Perú');
  bool _loading = false;
  String? _error;

  static final _usernamePattern = RegExp(r'^[A-Za-z0-9._]{4,30}$');
  static final _certificationPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9./-]{2,49}$');

  @override
  void initState() {
    super.initState();
    final email = AuthService.instance.pendingGoogle?.email ?? '';
    final suggestion = email.split('@').first.replaceAll(RegExp(r'[^A-Za-z0-9._]'), '');
    if (suggestion.length >= 4) _username.text = suggestion.length > 30 ? suggestion.substring(0, 30) : suggestion;
  }

  @override
  void dispose() {
    for (final c in [_username, _speciality, _certification, _phone, _street, _number, _city, _postalCode, _country]) {
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
      await AuthService.instance.completeGoogleRegistration(
        username: _username.text.trim(),
        phone: _phone.text.trim(),
        street: _street.text.trim(),
        number: _number.text.trim(),
        city: _city.text.trim(),
        postalCode: _postalCode.text.trim(),
        country: _country.text.trim(),
        speciality: _speciality.text.trim(),
        certificationNumber: _certification.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeShell()), (_) => false);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _field(String labelKey, TextEditingController controller, IconData icon,
      {String? Function(String?)? validator, TextInputType? keyboardType, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FieldLabel(tr(labelKey)),
        TextFormField(
          controller: controller,
          enabled: !_loading,
          validator: validator,
          keyboardType: keyboardType,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(prefixIcon: Icon(icon), hintText: hint),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Watch(builder: (context) {
      final google = AuthService.instance.pendingGoogle;
      final text = Theme.of(context).textTheme;
      return Scaffold(
        appBar: AppBar(title: Text(tr('createAccount'))),
        body: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 24), children: [
            AppCard(
              child: Row(children: [
                const IconCircle(icon: Icons.account_circle_outlined, color: AppColors.primary, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(google?.displayName ?? '', style: text.titleMedium),
                    Text(google?.email ?? '', style: text.bodySmall),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Text(tr('googleSignUpIntro'), style: text.bodyMedium?.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            _field('username', _username, Icons.alternate_email,
                validator: (v) => _match(v, _usernamePattern, 'usernameInvalid')),
            _field('speciality', _speciality, Icons.ac_unit, hint: tr('specialityHint'), validator: _required),
            _field('certificationNumber', _certification, Icons.badge_outlined,
                hint: 'CERT-2024-001', validator: (v) => _match(v, _certificationPattern, 'certificationInvalid')),
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
              onPressed: _loading || google == null ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(tr('createAccount')),
            ),
          ]),
        ),
      );
    });
  }
}
