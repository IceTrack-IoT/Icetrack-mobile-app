import '../../../shared/infrastructure/uuid.dart';
import '../../domain/model/intervention_report.dart';
import '../../domain/model/service_request.dart';
import '../resources/register_intervention_resource.dart';
import '../resources/service_request_resource.dart';

/// Translates between the Service Request JSON contract and the domain model.
class ServiceRequestAssembler {
  ServiceRequestAssembler._();

  static ServiceRequest toEntity(ServiceRequestResource r) => ServiceRequest(
        id: r.id,
        equipmentId: r.equipmentId,
        siteId: r.siteId,
        technicianId: r.technicianId,
        equipmentName: r.equipmentName,
        siteName: r.siteName,
        type: r.type == 'PREVENTIVE_MAINTENANCE' ? ServiceType.preventiveMaintenance : ServiceType.repair,
        priority: _priority(r.priority),
        description: r.description,
        status: statusFromApi(r.status),
        sourceAlertId: r.sourceAlertId,
        createdAt: parseInstant(r.createdAt),
        assignedAt: parseInstant(r.assignedAt),
        startedAt: parseInstant(r.startedAt),
        completedAt: parseInstant(r.completedAt),
        canceledAt: parseInstant(r.canceledAt),
        cancelReason: r.cancelReason,
        hasIntervention: r.hasIntervention,
        history: r.history
            .map((h) => StatusTransition(
                  fromStatus: h.fromStatus == null ? null : statusFromApi(h.fromStatus!),
                  toStatus: statusFromApi(h.toStatus),
                  occurredAt: parseInstant(h.occurredAt),
                  reason: h.reason,
                ))
            .toList(),
      );

  static ServiceStatus statusFromApi(String value) {
    switch (value) {
      case 'ACCEPTED':
        return ServiceStatus.accepted;
      case 'IN_PROGRESS':
        return ServiceStatus.inProgress;
      case 'COMPLETED':
        return ServiceStatus.completed;
      case 'CANCELED':
        return ServiceStatus.canceled;
      default:
        return ServiceStatus.pending;
    }
  }

  static ServicePriority _priority(String value) {
    switch (value) {
      case 'URGENT':
        return ServicePriority.urgent;
      case 'HIGH':
        return ServicePriority.high;
      case 'LOW':
        return ServicePriority.low;
      default:
        return ServicePriority.medium;
    }
  }

  static RegisterInterventionResource toRegisterResource(InterventionReport report) => RegisterInterventionResource(
        serviceRequestId: report.serviceRequestId,
        clientGeneratedId: report.clientGeneratedId,
        diagnosis: report.diagnosis,
        actionsTaken: report.actionsTaken,
        spareParts: report.spareParts,
        photoEvidence: report.photoEvidence,
        completedAt: isoUtc(report.completedAt),
      );
}
