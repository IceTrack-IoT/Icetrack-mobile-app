/// Kind of refrigeration unit.
enum EquipmentType { displayCase, coldRoom, refrigerator, other }

/// Whether the unit is reporting, as evaluated by the server (`connectivity.state`).
enum ConnectivityState { reporting, silent, neverReported, notMonitored }

/// Refrigeration unit (Assets bounded context). A technician can only read the
/// units of a request that is PENDING, ACCEPTED or IN_PROGRESS.
class Equipment {
  const Equipment({
    required this.id,
    required this.siteId,
    required this.name,
    required this.type,
    required this.status,
    required this.minCelsius,
    required this.maxCelsius,
    required this.connectivity,
    required this.underMaintenance,
    this.uid,
    this.siteName,
    this.lastReadingAt,
    this.lastKnownTemperature,
    this.lastReceivedAt,
  });

  final int id;
  final int siteId;
  final String? uid;
  final String name;
  final String? siteName;
  final EquipmentType type;

  /// ACTIVE, MAINTENANCE, REPAIR or DEACTIVATED.
  final String status;
  final double minCelsius;
  final double maxCelsius;
  final DateTime? lastReadingAt;
  final double? lastKnownTemperature;
  final ConnectivityState connectivity;
  final DateTime? lastReceivedAt;
  final bool underMaintenance;

  bool get isOutOfRange =>
      lastKnownTemperature != null && (lastKnownTemperature! > maxCelsius || lastKnownTemperature! < minCelsius);

  bool get isSilent => connectivity == ConnectivityState.silent || connectivity == ConnectivityState.neverReported;
}
