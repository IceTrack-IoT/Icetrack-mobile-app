/// `StatusTransitionResource` (nested in `ServiceRequestResource.history`).
class StatusTransitionResource {
  const StatusTransitionResource({this.fromStatus, required this.toStatus, this.occurredAt, this.reason});

  factory StatusTransitionResource.fromJson(Map<String, dynamic> json) => StatusTransitionResource(
        fromStatus: json['from_status'] as String?,
        toStatus: json['to_status'] as String? ?? 'PENDING',
        occurredAt: json['occurred_at'] as String?,
        reason: json['reason'] as String?,
      );

  final String? fromStatus;
  final String toStatus;
  final String? occurredAt;
  final String? reason;
}

/// `IssuedEdgeGrantResource`: only present in the response of `PUT /accept`
/// and `POST /edge-grant`. The token opens the on-site gateway (steps 3+).
class EdgeGrantResource {
  const EdgeGrantResource({required this.token, this.expiresAt});

  factory EdgeGrantResource.fromJson(Map<String, dynamic> json) =>
      EdgeGrantResource(token: json['token'] as String, expiresAt: json['expires_at'] as String?);

  final String token;
  final String? expiresAt;
}

/// `ServiceRequestResource` (response of list, detail and every state change).
class ServiceRequestResource {
  const ServiceRequestResource({
    required this.id,
    required this.equipmentId,
    required this.siteId,
    this.technicianId,
    this.equipmentName,
    this.siteName,
    required this.type,
    required this.priority,
    required this.description,
    required this.status,
    this.sourceAlertId,
    this.createdAt,
    this.assignedAt,
    this.startedAt,
    this.completedAt,
    this.canceledAt,
    this.cancelReason,
    this.history = const [],
    this.hasIntervention = false,
    this.edgeGrant,
  });

  factory ServiceRequestResource.fromJson(Map<String, dynamic> json) => ServiceRequestResource(
        id: (json['id'] as num).toInt(),
        equipmentId: (json['equipment_id'] as num).toInt(),
        siteId: (json['site_id'] as num?)?.toInt() ?? 0,
        technicianId: (json['technician_id'] as num?)?.toInt(),
        equipmentName: json['equipment_name'] as String?,
        siteName: json['site_name'] as String?,
        type: json['type'] as String? ?? 'REPAIR',
        priority: json['priority'] as String? ?? 'MEDIUM',
        description: json['description'] as String? ?? '',
        status: json['status'] as String? ?? 'PENDING',
        sourceAlertId: (json['source_alert_id'] as num?)?.toInt(),
        createdAt: json['created_at'] as String?,
        assignedAt: json['assigned_at'] as String?,
        startedAt: json['started_at'] as String?,
        completedAt: json['completed_at'] as String?,
        canceledAt: json['canceled_at'] as String?,
        cancelReason: json['cancel_reason'] as String?,
        history: (json['history'] as List<dynamic>? ?? const [])
            .map((e) => StatusTransitionResource.fromJson(e as Map<String, dynamic>))
            .toList(),
        hasIntervention: json['intervention'] != null || (json['has_intervention'] as bool? ?? false),
        edgeGrant: json['edge_grant'] is Map<String, dynamic>
            ? EdgeGrantResource.fromJson(json['edge_grant'] as Map<String, dynamic>)
            : null,
      );

  final int id;
  final int equipmentId;
  final int siteId;
  final int? technicianId;
  final String? equipmentName;
  final String? siteName;
  final String type;
  final String priority;
  final String description;
  final String status;
  final int? sourceAlertId;
  final String? createdAt;
  final String? assignedAt;
  final String? startedAt;
  final String? completedAt;
  final String? canceledAt;
  final String? cancelReason;
  final List<StatusTransitionResource> history;
  final bool hasIntervention;
  final EdgeGrantResource? edgeGrant;
}

/// `PagedServiceRequestResource` (items are under `content`).
class PagedServiceRequestResource {
  const PagedServiceRequestResource({required this.content, required this.totalElements});

  factory PagedServiceRequestResource.fromJson(Map<String, dynamic> json) => PagedServiceRequestResource(
        content: (json['content'] as List<dynamic>? ?? const [])
            .map((e) => ServiceRequestResource.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalElements: (json['total_elements'] as num?)?.toInt() ?? 0,
      );

  final List<ServiceRequestResource> content;
  final int totalElements;
}
