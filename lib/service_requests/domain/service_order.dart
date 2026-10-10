enum OrderStatus { pending, accepted, inProgress, completed, rejected }

enum OrderPriority { high, medium, low }

class ServiceOrder {
  ServiceOrder({
    required this.code,
    required this.equipmentId,
    required this.equipmentName,
    required this.serviceType,
    required this.siteName,
    required this.address,
    required this.scheduledAt,
    required this.priority,
    required this.status,
    required this.requestedBy,
    required this.contactPhone,
    required this.reportedIssue,
  });

  final String code;
  final String equipmentId;
  final String equipmentName;
  final String serviceType;
  final String siteName;
  final String address;
  final String scheduledAt;
  final OrderPriority priority;
  OrderStatus status;
  final String requestedBy;
  final String contactPhone;
  final String reportedIssue;
}

class Intervention {
  Intervention({
    required this.localId,
    required this.orderCode,
    required this.diagnosis,
    required this.actions,
    required this.spareParts,
    required this.photoCount,
  });

  /// Unique local identifier that prevents duplicates when syncing (US-31).
  final String localId;
  final String orderCode;
  final String diagnosis;
  final List<String> actions;
  final List<String> spareParts;
  final int photoCount;
}
