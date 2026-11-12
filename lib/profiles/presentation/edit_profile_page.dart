import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../iam/presentation/sign_in_page.dart';
import '../../shared/presentation/error_text.dart';
import '../application/profile_service.dart';
import '../domain/model/street_address.dart';
import '../domain/model/technician_profile.dart';

/// Edit the professional profile: contact, speciality and certification (US-07).
/// Sends `PUT /profiles/technicians/{id}`; the email cannot be changed.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.profile});

  final TechnicianProfile profile;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullName;
  late final TextEditingController _phone;
  late final TextEditingController _street;
  late final TextEditingController _number;
  late final TextEditingController _city;
  late final TextEditingController _postalCode;
  late final TextEditingController _country;
  late final TextEditingController _speciality;
  late final TextEditingController _certification;
  bool _saving = false;
  String? _error;

  static final _certificationPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9./-]{2,49}$');

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    final address = StreetAddress.parse(p.address);
    _fullName = TextEditingController(text: p.fullName);
    _phone = TextEditingController(text: p.phone);
    _street = TextEditingController(text: address.street);
    _number = TextEditingController(text: address.number);
    _city = TextEditingController(text: address.city);
    _postalCode = TextEditingController(text: address.postalCode);
    _country = TextEditingController(text: address.country);
    _speciality = TextEditingController(text: p.speciality);
    _certification = TextEditingController(text: p.certificationNumber);
  }

  @override
  void dispose() {
    for (final c in [_fullName, _phone, _street, _number, _city, _postalCode, _country, _speciality, _certification]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) => (value == null || value.trim().isEmpty) ? tr('fieldRequired') : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (AppState.instance.isOffline) {
      setState(() => _error = tr('needsConnection'));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ProfileService.instance.updateProfile(
        current: widget.profile,
        fullName: _fullName.text.trim(),
        phone: _phone.text.trim(),
        address: StreetAddress(
          street: _street.text.trim(),
          number: _number.text.trim(),
          city: _city.text.trim(),
          postalCode: _postalCode.text.trim(),
          country: _country.text.trim(),
        ),
        speciality: _speciality.text.trim(),
        certificationNumber: _certification.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
        content: Text(tr('profileSaved')),
      ));
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(String labelKey, TextEditingController controller, IconData icon,
      {String? Function(String?)? validator, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FieldLabel(tr(labelKey)),
        TextFormField(
          controller: controller,
          enabled: !_saving,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(prefixIcon: Icon(icon)),
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
        appBar: AppBar(title: Text(tr('editProfile'))),
        body: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 24), children: [
            Text(tr('editProfileIntro'), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 8),
            _section('sectionProfessional'),
            _field('fullName', _fullName, Icons.person_outline, validator: _required),
            _field('speciality', _speciality, Icons.ac_unit, validator: _required),
            _field('certificationNumber', _certification, Icons.badge_outlined, validator: (v) {
              final empty = _required(v);
              if (empty != null) return empty;
              return _certificationPattern.hasMatch(v!.trim()) ? null : tr('certificationInvalid');
            }),
            _section('sectionContact'),
            FieldLabel(tr('email')),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                initialValue: widget.profile.email,
                enabled: false,
                decoration: InputDecoration(prefixIcon: const Icon(Icons.mail_outline), helperText: tr('emailReadOnly')),
              ),
            ),
            _field('phone', _phone, Icons.phone_outlined, validator: _required, keyboardType: TextInputType.phone),
            _field('street', _street, Icons.signpost_outlined, validator: _required),
            _field('streetNumber', _number, Icons.tag),
            _field('city', _city, Icons.location_city_outlined, validator: _required),
            _field('postalCode', _postalCode, Icons.markunread_mailbox_outlined,
                validator: _required, keyboardType: TextInputType.number),
            _field('country', _country, Icons.public, validator: _required),
            if (_error != null) ...[
              FormMessage(text: _error!),
              const SizedBox(height: 16),
            ],
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(tr('saveChanges')),
            ),
          ]),
        ),
      );
    });
  }
}
