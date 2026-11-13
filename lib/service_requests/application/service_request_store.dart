import 'package:flutter/foundation.dart';

import '../../core/state/app_state.dart';
import '../../shared/infrastructure/api_exception.dart';
import '../domain/model/intervention_report.dart';
import '../domain/model/service_request.dart';
import '../infrastructure/assemblers/service_request_assembler.dart';
import '../infrastructure/edge_grant_storage.dart';
import '../infrastructure/offline_intervention_queue.dart';
import '../infrastructure/resources/register_intervention_resource.dart';
import '../infrastructure/resources/service_request_resource.dart';
import '../infrastructure/service_requests_api.dart';

/// Application service of the Service Request context for the technician:
/// assigned requests, accept / reject / start (US-30, US-33) and the
/// intervention with its offline queue (US-31).
class ServiceRequestStore extends ChangeNotifier {
  ServiceRequestStore._();

  static final ServiceRequestStore instance = ServiceRequestStore._();

  final ServiceRequestsApi _api = ServiceRequestsApi();
  final OfflineInterventionQueue _queue = OfflineInterventionQueue();
  final EdgeGrantStorage _edgeGrants = EdgeGrantStorage();

  List<ServiceRequest> requests = [];
  List<RegisterInterventionResource> pending = [];
  bool isLoading = false;
  bool hasLoaded = false;

  /// Last error of a list refresh (shown as a banner; the previous list is kept).
  ApiException? loadError;

  /// Queued interventions the backend refused when replayed (request canceled or reassigned).
  final List<String> syncIssues = [];

  DateTime? lastSync;

  bool get isOfflineNow => AppState.instance.isOffline || (loadError?.isNetwork ?? false);

  ServiceRequest? byId(int id) {
    for (final r in requests) {
      if (r.id == id) return r;
    }
    return null;
  }

  bool isPendingSync(int requestId) => pending.any((p) => p.serviceRequestId == requestId);

  int countBy(ServiceStatus status) => requests.where((r) => r.status == status && !isPendingSync(r.id)).length;

  /// Replays the offline queue and reloads the assigned requests.
  Future<void> refresh() async {
    if (isLoading) return;
    isLoading = true;
    notifyListeners();
    try {
      pending = await _queue.readAll();
      if (AppState.instance.isOffline) {
        loadError = const ApiException.network();
        return;
      }
      await _syncPending();
      final page = await _api.listAssigned();
      requests = page.content.map(ServiceRequestAssembler.toEntity).toList();
      loadError = null;
      hasLoaded = true;
      lastSync = DateTime.now();
    } on ApiException catch (e) {
      loadError = e;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Reads one request from the backend (detail screen) and updates the cached list.
  Future<ServiceRequest> load(int id) async {
    final request = ServiceRequestAssembler.toEntity(await _api.getById(id));
    _replace(request);
    return request;
  }

  Future<void> accept(ServiceRequest request) async {
    _ensureOnline();
    final resource = await _api.accept(request.id);
    final grant = resource.edgeGrant;
    if (grant != null) await _edgeGrants.save(request.id, grant.token);
    _apply(resource);
  }

  Future<void> reject(ServiceRequest request, String reason) async {
    _ensureOnline();
    await _api.reject(request.id, reason);
    // Once rejected the request is no longer assigned to this technician.
    requests.removeWhere((r) => r.id == request.id);
    await _edgeGrants.delete(request.id);
    notifyListeners();
  }

  Future<void> start(ServiceRequest request) async {
    _ensureOnline();
    _apply(await _api.start(request.id, DateTime.now()));
  }

  /// Sends the intervention; without connection it is stored and replayed later.
  Future<SubmitResult> submitIntervention(InterventionReport report) async {
    final resource = ServiceRequestAssembler.toRegisterResource(report);
    if (AppState.instance.isOffline) return _enqueue(resource);
    try {
      await _api.registerIntervention(resource);
    } on ApiException catch (e) {
      if (e.isNetwork) return _enqueue(resource);
      rethrow;
    }
    await _edgeGrants.delete(report.serviceRequestId);
    _markCompleted(report.serviceRequestId);
    lastSync = DateTime.now();
    notifyListeners();
    return SubmitResult.sent;
  }

  /// Token that lets the technician operate the on-site gateway (US-40, US-48, US-49).
  /// It is shown by the backend only once, when accepting; if it was lost, a new one is issued.
  Future<String> edgeGrant(int requestId, {bool renew = false}) async {
    if (!renew) {
      final stored = await _edgeGrants.read(requestId);
      if (stored != null && stored.isNotEmpty) return stored;
    }
    _ensureOnline();
    final grant = await _api.regenerateEdgeGrant(requestId);
    await _edgeGrants.save(requestId, grant.token);
    return grant.token;
  }

  /// Manual "Sync now" (profile) or automatic after reconnecting.
  Future<void> syncNow() => refresh();

  void clearSyncIssues() {
    syncIssues.clear();
    notifyListeners();
  }

  /// Forget the cached list on sign-out. The offline queue stays on the phone,
  /// so interventions registered without connection are never lost.
  Future<void> reset() async {
    requests = [];
    pending = [];
    hasLoaded = false;
    loadError = null;
    lastSync = null;
    syncIssues.clear();
    notifyListeners();
  }

  Future<SubmitResult> _enqueue(RegisterInterventionResource resource) async {
    await _queue.add(resource);
    pending = await _queue.readAll();
    notifyListeners();
    return SubmitResult.queued;
  }

  Future<void> _syncPending() async {
    for (final item in List.of(pending)) {
      try {
        await _api.registerIntervention(item);
        await _edgeGrants.delete(item.serviceRequestId);
      } on ApiException catch (e) {
        if (e.isNetwork) rethrow; // still offline: keep the rest for later
        // 404: no longer assigned; 409: canceled, reassigned or already completed.
        syncIssues.add('OS-${item.serviceRequestId}');
      }
      await _queue.remove(item.clientGeneratedId);
    }
    pending = await _queue.readAll();
  }

  void _ensureOnline() {
    if (AppState.instance.isOffline) throw const ApiException.network();
  }

  void _apply(ServiceRequestResource resource) {
    _replace(ServiceRequestAssembler.toEntity(resource));
    notifyListeners();
  }

  void _replace(ServiceRequest request) {
    final index = requests.indexWhere((r) => r.id == request.id);
    if (index >= 0) {
      requests[index] = request;
    } else {
      requests.insert(0, request);
    }
    notifyListeners();
  }

  void _markCompleted(int requestId) {
    final current = byId(requestId);
    if (current != null) _replace(current.copyWith(status: ServiceStatus.completed));
  }
}
