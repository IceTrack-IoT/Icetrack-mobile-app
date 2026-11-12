/// Street address value object, split as the backend expects it in the update.
/// The profile read returns the address as one text ("Av. Primavera 123, Lima, 15023, Peru"),
/// so [StreetAddress.parse] splits it back to pre-fill the edit form.
class StreetAddress {
  const StreetAddress({
    required this.street,
    this.number = '',
    required this.city,
    required this.postalCode,
    required this.country,
  });

  factory StreetAddress.parse(String text) {
    final parts = text.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (parts.length < 4) {
      return StreetAddress(street: text.trim(), city: '', postalCode: '', country: '');
    }
    final country = parts.removeLast();
    final postalCode = parts.removeLast();
    final city = parts.removeLast();
    var street = parts.join(', ');
    var number = '';
    final match = RegExp(r'^(.*\D)\s+(\d[\w-]*)$').firstMatch(street);
    if (match != null) {
      street = match.group(1)!.trim();
      number = match.group(2)!;
    }
    return StreetAddress(street: street, number: number, city: city, postalCode: postalCode, country: country);
  }

  final String street;
  final String number;
  final String city;
  final String postalCode;
  final String country;
}
