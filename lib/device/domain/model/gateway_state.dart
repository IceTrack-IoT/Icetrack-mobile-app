/// Where the technician reaches the on-site gateway (Edge Service) and which
/// monitoring device of the unit the commands are for.
class GatewayConnection {
  const GatewayConnection({required this.baseUrl, required this.deviceUid});

  /// Local address of the gateway, for example `http://192.168.1.50:5000`.
  final String baseUrl;

  /// Identifier of the ESP32 board paired with the unit (its `deviceId`).
  final String deviceUid;

  bool get isComplete => baseUrl.isNotEmpty && deviceUid.isNotEmpty;
}

/// State of the device as reported by the gateway after a command (US-40).
class GatewayState {
  const GatewayState({
    required this.alarmActive,
    required this.buzzerMuted,
    required this.signalTest,
    required this.maintenanceActive,
    this.maintenanceOrigin,
    this.maintenanceExpiresAt,
  });

  final bool alarmActive;
  final bool buzzerMuted;
  final bool signalTest;
  final bool maintenanceActive;

  /// APP or BUTTON.
  final String? maintenanceOrigin;
  final DateTime? maintenanceExpiresAt;
}
