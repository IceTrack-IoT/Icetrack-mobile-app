/// `EquipmentResource` with its nested `connectivity` (`EquipmentConnectivityResource`).
class EquipmentResource {
  const EquipmentResource({
    required this.id,
    required this.siteId,
    this.siteName,
    this.uid,
    required this.name,
    required this.equipmentType,
    required this.status,
    required this.minCelsius,
    required this.maxCelsius,
    this.lastReadingAt,
    this.lastKnownTemperature,
    this.connectivityState,
    this.lastReceivedAt,
    this.underMaintenance = false,
    this.online = false,
  });

  factory EquipmentResource.fromJson(Map<String, dynamic> json) {
    final connectivity = json['connectivity'] as Map<String, dynamic>?;
    return EquipmentResource(
      id: (json['id'] as num).toInt(),
      siteId: (json['site_id'] as num?)?.toInt() ?? 0,
      siteName: json['site_name'] as String?,
      uid: json['uid'] as String?,
      name: json['name'] as String? ?? '',
      equipmentType: json['equipment_type'] as String? ?? 'OTHER',
      status: json['status'] as String? ?? 'ACTIVE',
      minCelsius: (json['min_celsius'] as num?)?.toDouble() ?? 0,
      maxCelsius: (json['max_celsius'] as num?)?.toDouble() ?? 0,
      lastReadingAt: json['last_reading_at'] as String?,
      lastKnownTemperature: (json['last_known_temperature'] as num?)?.toDouble(),
      connectivityState: connectivity?['state'] as String?,
      lastReceivedAt: connectivity?['last_received_at'] as String?,
      underMaintenance: connectivity?['under_maintenance'] as bool? ?? false,
      online: json['online'] as bool? ?? false,
    );
  }

  final int id;
  final int siteId;
  final String? siteName;
  final String? uid;
  final String name;
  final String equipmentType;
  final String status;
  final double minCelsius;
  final double maxCelsius;
  final String? lastReadingAt;
  final double? lastKnownTemperature;
  final String? connectivityState;
  final String? lastReceivedAt;
  final bool underMaintenance;

  /// Deprecated by the backend; only used when `connectivity` is missing.
  final bool online;
}
