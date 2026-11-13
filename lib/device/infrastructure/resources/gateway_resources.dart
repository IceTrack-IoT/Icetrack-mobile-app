/// Response of every technician command of the Edge Service. The gateway API uses camelCase.
class GatewayDirectivesResource {
  const GatewayDirectivesResource({
    required this.alarmActive,
    required this.buzzerMuted,
    required this.signalTest,
    required this.maintenanceActive,
    this.maintenanceOrigin,
    this.maintenanceExpiresAt,
    this.idempotentReplay = false,
  });

  factory GatewayDirectivesResource.fromJson(Map<String, dynamic> json) {
    final maintenance = json['maintenanceMode'] as Map<String, dynamic>? ?? const {};
    return GatewayDirectivesResource(
      alarmActive: json['alarmActive'] as bool? ?? false,
      buzzerMuted: json['buzzerMuted'] as bool? ?? false,
      signalTest: json['signalTest'] as bool? ?? false,
      maintenanceActive: maintenance['active'] as bool? ?? false,
      maintenanceOrigin: maintenance['origin'] as String?,
      maintenanceExpiresAt: maintenance['expiresAt'] as String?,
      idempotentReplay: json['idempotentReplay'] as bool? ?? false,
    );
  }

  final bool alarmActive;
  final bool buzzerMuted;
  final bool signalTest;
  final bool maintenanceActive;
  final String? maintenanceOrigin;
  final String? maintenanceExpiresAt;
  final bool idempotentReplay;
}
