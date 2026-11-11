/// Intervention the technician registers to complete a request (US-31).
/// [clientGeneratedId] is created once and kept across retries, so replaying
/// it after a lost connection never creates a duplicate.
class InterventionReport {
  const InterventionReport({
    required this.clientGeneratedId,
    required this.serviceRequestId,
    required this.diagnosis,
    required this.actionsTaken,
    required this.spareParts,
    required this.completedAt,
    this.photoEvidence = const [],
  });

  final String clientGeneratedId;
  final int serviceRequestId;
  final String diagnosis;
  final String actionsTaken;
  final List<String> spareParts;
  final List<String> photoEvidence;
  final DateTime completedAt;
}

/// Result of submitting an intervention.
enum SubmitResult { sent, queued }
