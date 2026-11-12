import 'package:flutter/foundation.dart';

import '../../assets/application/assets_service.dart';
import '../../assets/domain/model/equipment.dart';
import '../../service_requests/application/service_request_store.dart';
import '../../service_requests/domain/model/intervention_report.dart';
import '../../service_requests/infrastructure/assemblers/service_request_assembler.dart';
import '../../service_requests/infrastructure/service_requests_api.dart';
import '../../shared/infrastructure/api_exception.dart';
import '../domain/model/alert.dart';
import '../domain/model/equipment_health.dart';
import '../domain/model/telemetry_point.dart';
import '../infrastructure/assemblers/monitoring_assembler.dart';
import '../infrastructure/monitoring_api.dart';
import '../infrastructure/resources/monitoring_resources.dart';

/// Everything the equipment screen shows (US-27, US-33).
class EquipmentOverview {
  const EquipmentOverview({
    required this.equipment,
    required this.points,
    required this.openAlerts,
    required this.interventions,
  });

  final Equipment equipment;
  final List<TelemetryPoint> points;
  final List<Alert> openAlerts;
  final List<InterventionRecord> interventions;

  EquipmentHealth get health => healthOf(equipment, openAlerts);
}

/// One row of the alerts tab: a unit of my active orders with its open alert,
/// or with no alert when it simply stopped reporting.
class AlertEntry {
  const AlertEntry({required this.equipment, this.alert});

  final Equipment equipment;
  final Alert? alert;

  EquipmentHealth get health => healthOf(equipment, alert == null ? const [] : [alert!]);
}

/// Application service of the Monitoring and Alerting context for the technician.
class MonitoringStore extends ChangeNotifier {
  MonitoringStore._();

  static final MonitoringStore instance = MonitoringStore._();

  /// Hours of history drawn in the equipment chart.
  static const int historyHours = 12;

  final MonitoringApi _api = MonitoringApi();
  final ServiceRequestsApi _serviceRequestsApi = ServiceRequestsApi();
  final AssetsService _assets = AssetsService.instance;

  List<AlertEntry> alerts = [];
  bool isLoading = false;
  bool hasLoaded = false;
  ApiException? loadError;

  int countBy(EquipmentHealth health) => alerts.where((a) => a.health == health).length;

  /// Unit, last [historyHours] hours of telemetry, open alerts and past interventions, in parallel.
  Future<EquipmentOverview> overview(int equipmentId) async {
    final now = DateTime.now();
    final results = await Future.wait([
      _assets.equipment(equipmentId),
      _api.telemetry(equipmentId, from: now.subtract(const Duration(hours: historyHours)), to: now),
      _api.openAlerts(equipmentId),
      _serviceRequestsApi.interventionsOfEquipment(equipmentId),
    ]);
    final interventions = (results[3] as List).map((r) => ServiceRequestAssembler.toRecord(r)).toList()
      ..sort((a, b) => (b.completedAt ?? DateTime(0)).compareTo(a.completedAt ?? DateTime(0)));
    return EquipmentOverview(
      equipment: results[0] as Equipment,
      points: MonitoringAssembler.toPoints((results[1] as List).cast<TelemetryBucketResource>()),
      openAlerts: (results[2] as List).map((r) => MonitoringAssembler.toAlert(r)).toList(),
      interventions: interventions,
    );
  }

  /// Open alerts of the units in my active orders (alerts tab, US-32).
  Future<void> refreshAlerts() async {
    if (isLoading) return;
    isLoading = true;
    notifyListeners();
    try {
      final equipmentIds = ServiceRequestStore.instance.requests
          .where((r) => r.isActive)
          .map((r) => r.equipmentId)
          .toSet();
      final perUnit = await Future.wait(equipmentIds.map(_entriesFor));
      const rank = {
        EquipmentHealth.critical: 0,
        EquipmentHealth.offline: 1,
        EquipmentHealth.warning: 2,
        EquipmentHealth.normal: 3,
      };
      alerts = perUnit.expand((e) => e).toList()..sort((a, b) => rank[a.health]!.compareTo(rank[b.health]!));
      loadError = null;
      hasLoaded = true;
    } on ApiException catch (e) {
      loadError = e;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    alerts = [];
    hasLoaded = false;
    loadError = null;
    _assets.clear();
    notifyListeners();
  }

  Future<List<AlertEntry>> _entriesFor(int equipmentId) async {
    try {
      final equipment = await _assets.equipment(equipmentId);
      final open = (await _api.openAlerts(equipmentId)).map(MonitoringAssembler.toAlert).toList();
      if (open.isNotEmpty) return [for (final a in open) AlertEntry(equipment: equipment, alert: a)];
      if (equipment.isSilent || equipment.isOutOfRange) return [AlertEntry(equipment: equipment)];
      return [];
    } on ApiException catch (e) {
      // 404: the order stopped being active in the meantime; skip that unit.
      if (e.isNotFound) return [];
      rethrow;
    }
  }
}
