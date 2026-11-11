/// Lifecycle of a service request, as defined by the backend state machine.
/// A rejected request goes back to the owner unassigned, so it simply leaves the technician's list.
enum ServiceStatus { pending, accepted, inProgress, completed, canceled }

enum ServicePriority { urgent, high, medium, low }

enum ServiceType { preventiveMaintenance, repair }

class StatusTransition {
  const StatusTransition({required this.fromStatus, required this.toStatus, required this.occurredAt, this.reason});

  final ServiceStatus? fromStatus;
  final ServiceStatus toStatus;
  final DateTime? occurredAt;
  final String? reason;
}

/// Service request (work order) assigned to the technician (Service Request bounded context).
class ServiceRequest {
  const ServiceRequest({
    required this.id,
    required this.equipmentId,
    required this.siteId,
    required this.equipmentName,
    required this.siteName,
    required this.type,
    required this.priority,
    required this.description,
    required this.status,
    required this.createdAt,
    this.technicianId,
    this.sourceAlertId,
    this.assignedAt,
    this.startedAt,
    this.completedAt,
    this.canceledAt,
    this.cancelReason,
    this.history = const [],
    this.hasIntervention = false,
  });

  final int id;
  final int equipmentId;
  final int siteId;
  final int? technicianId;
  final String? equipmentName;
  final String? siteName;
  final ServiceType type;
  final ServicePriority priority;
  final String description;
  final ServiceStatus status;
  final int? sourceAlertId;
  final DateTime? createdAt;
  final DateTime? assignedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? canceledAt;
  final String? cancelReason;
  final List<StatusTransition> history;
  final bool hasIntervention;

  /// Display code used across the app and the designs (OS-42).
  String get code => 'OS-$id';

  bool get isActive =>
      status == ServiceStatus.pending || status == ServiceStatus.accepted || status == ServiceStatus.inProgress;

  ServiceRequest copyWith({ServiceStatus? status}) => ServiceRequest(
        id: id,
        equipmentId: equipmentId,
        siteId: siteId,
        technicianId: technicianId,
        equipmentName: equipmentName,
        siteName: siteName,
        type: type,
        priority: priority,
        description: description,
        status: status ?? this.status,
        sourceAlertId: sourceAlertId,
        createdAt: createdAt,
        assignedAt: assignedAt,
        startedAt: startedAt,
        completedAt: completedAt,
        canceledAt: canceledAt,
        cancelReason: cancelReason,
        history: history,
        hasIntervention: hasIntervention,
      );
}
