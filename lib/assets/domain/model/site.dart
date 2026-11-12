/// Place where the owner's units are installed (Assets bounded context).
/// The address is verified by the backend with Google Maps (Geocoding API).
class Site {
  const Site({
    required this.id,
    required this.name,
    required this.address,
    required this.contactName,
    required this.phone,
    this.latitude,
    this.longitude,
    this.navigationUrl,
  });

  final int id;
  final String name;
  final String address;
  final String contactName;
  final String phone;
  final double? latitude;
  final double? longitude;

  /// Ready Google Maps directions URL built by the backend (US-47).
  final String? navigationUrl;

  bool get hasLocation => latitude != null && longitude != null;
}
