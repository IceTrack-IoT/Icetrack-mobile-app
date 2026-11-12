/// `SiteResource`. `location` and `navigation_url` are omitted when the site is not located.
class SiteResource {
  const SiteResource({
    required this.id,
    required this.name,
    required this.address,
    required this.contactName,
    required this.phone,
    this.latitude,
    this.longitude,
    this.navigationUrl,
  });

  factory SiteResource.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    return SiteResource(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      contactName: json['contact_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      latitude: (location?['latitude'] as num?)?.toDouble(),
      longitude: (location?['longitude'] as num?)?.toDouble(),
      navigationUrl: json['navigation_url'] as String?,
    );
  }

  final int id;
  final String name;
  final String address;
  final String contactName;
  final String phone;
  final double? latitude;
  final double? longitude;
  final String? navigationUrl;
}
