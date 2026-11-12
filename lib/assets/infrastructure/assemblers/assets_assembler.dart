import '../../../shared/infrastructure/uuid.dart';
import '../../domain/model/equipment.dart';
import '../../domain/model/site.dart';
import '../resources/equipment_resource.dart';
import '../resources/site_resource.dart';

class AssetsAssembler {
  AssetsAssembler._();

  static Equipment toEquipment(EquipmentResource r) => Equipment(
        id: r.id,
        siteId: r.siteId,
        siteName: r.siteName,
        uid: r.uid,
        name: r.name,
        type: switch (r.equipmentType) {
          'DISPLAY_CASE' => EquipmentType.displayCase,
          'COLD_ROOM' => EquipmentType.coldRoom,
          'REFRIGERATOR' => EquipmentType.refrigerator,
          _ => EquipmentType.other,
        },
        status: r.status,
        minCelsius: r.minCelsius,
        maxCelsius: r.maxCelsius,
        lastReadingAt: parseInstant(r.lastReadingAt),
        lastKnownTemperature: r.lastKnownTemperature,
        connectivity: switch (r.connectivityState) {
          'REPORTING' => ConnectivityState.reporting,
          'SILENT' => ConnectivityState.silent,
          'NEVER_REPORTED' => ConnectivityState.neverReported,
          'NOT_MONITORED' => ConnectivityState.notMonitored,
          _ => r.online ? ConnectivityState.reporting : ConnectivityState.silent,
        },
        lastReceivedAt: parseInstant(r.lastReceivedAt),
        underMaintenance: r.underMaintenance,
      );

  static Site toSite(SiteResource r) => Site(
        id: r.id,
        name: r.name,
        address: r.address,
        contactName: r.contactName,
        phone: r.phone,
        latitude: r.latitude,
        longitude: r.longitude,
        navigationUrl: r.navigationUrl,
      );
}
