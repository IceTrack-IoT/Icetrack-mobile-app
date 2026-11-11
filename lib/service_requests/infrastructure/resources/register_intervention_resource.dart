/// Request body of `POST /interventions`. Also the format stored in the offline queue.
class RegisterInterventionResource {
  const RegisterInterventionResource({
    required this.serviceRequestId,
    required this.clientGeneratedId,
    required this.diagnosis,
    required this.actionsTaken,
    required this.spareParts,
    required this.photoEvidence,
    required this.completedAt,
  });

  factory RegisterInterventionResource.fromJson(Map<String, dynamic> json) => RegisterInterventionResource(
        serviceRequestId: (json['service_request_id'] as num).toInt(),
        clientGeneratedId: json['client_generated_id'] as String,
        diagnosis: json['diagnosis'] as String,
        actionsTaken: json['actions_taken'] as String,
        spareParts: (json['spare_parts'] as List<dynamic>? ?? const []).cast<String>(),
        photoEvidence: (json['photo_evidence'] as List<dynamic>? ?? const []).cast<String>(),
        completedAt: json['completed_at'] as String?,
      );

  final int serviceRequestId;
  final String clientGeneratedId;
  final String diagnosis;
  final String actionsTaken;
  final List<String> spareParts;
  final List<String> photoEvidence;

  /// Device instant (UTC `Z`) when the work finished; kept when replayed later.
  final String? completedAt;

  Map<String, dynamic> toJson() => {
        'service_request_id': serviceRequestId,
        'client_generated_id': clientGeneratedId,
        'diagnosis': diagnosis,
        'actions_taken': actionsTaken,
        'spare_parts': spareParts,
        'photo_evidence': photoEvidence,
        if (completedAt != null) 'completed_at': completedAt,
      };
}
