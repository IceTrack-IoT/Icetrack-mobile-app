import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/i18n/date_format.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../service_requests/application/service_request_store.dart';
import '../../shared/presentation/error_text.dart';
import '../application/monitoring_store.dart';
import '../domain/model/alert.dart';
import '../domain/model/equipment_health.dart';
import 'equipment_page.dart';

String healthLabel(EquipmentHealth h) => switch (h) {
      EquipmentHealth.critical => tr('critical'),
      EquipmentHealth.warning => tr('warningLabel'),
      EquipmentHealth.offline => tr('offlineLabel'),
      EquipmentHealth.normal => tr('inRange'),
    };

/// Screen 12: Active alerts of the units in my active orders (US-32).
/// Reads `GET /alerts/equipment/{id}/open` for each unit of an active order.
class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  int _seenRequests = -1;

  @override
  Widget build(BuildContext context) {
    return Watch(builder: (context) {
      final store = MonitoringStore.instance;
      final requests = ServiceRequestStore.instance;
      final text = Theme.of(context).textTheme;
      // Reload once the orders are known, and again when they change.
      final activeCount = requests.requests.where((r) => r.isActive).length;
      if (requests.hasLoaded && activeCount != _seenRequests && !store.isLoading && !AppState.instance.isOffline) {
        _seenRequests = activeCount;
        WidgetsBinding.instance.addPostFrameCallback((_) => store.refreshAlerts());
      }
      return SafeArea(
        child: RefreshIndicator(
          onRefresh: store.refreshAlerts,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              Text(tr('activeAlerts'), style: text.headlineSmall),
              Text(tr('activeAlertsSub'), style: text.bodyMedium?.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              Row(children: [
                for (final h in [EquipmentHealth.critical, EquipmentHealth.warning, EquipmentHealth.offline]) ...[
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${store.countBy(h)}', style: AppTheme.numeric(size: 28, color: healthColor(h))),
                        Text(healthLabel(h), style: text.bodySmall),
                      ]),
                    ),
                  ),
                  if (h != EquipmentHealth.offline) const SizedBox(width: 10),
                ],
              ]),
              const SizedBox(height: 16),
              if (store.loadError != null) ...[
                Text(errorText(store.loadError!), style: const TextStyle(color: AppColors.danger)),
                const SizedBox(height: 12),
              ],
              if (store.isLoading && !store.hasLoaded)
                const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
              else if (store.alerts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(tr('noAlerts'), textAlign: TextAlign.center, style: text.bodyMedium),
                )
              else
                for (final entry in store.alerts) ...[
                  _AlertCard(entry: entry),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      );
    });
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.entry});

  final AlertEntry entry;

  String _detail() {
    final alert = entry.alert;
    if (alert == null) {
      return entry.equipment.isSilent
          ? '${tr('noReadingsSince')} ${formatDateTime(entry.equipment.lastReadingAt)}'
          : tr('outOfRange');
    }
    final kind = alert.type == AlertType.deviceOffline ? tr('alertDeviceOffline') : tr('alertExcursion');
    return '$kind · ${formatDateTime(alert.openedAt)}';
  }

  @override
  Widget build(BuildContext context) {
    final eq = entry.equipment;
    final health = entry.health;
    final color = healthColor(health);
    final temperature = entry.alert?.peakTemperature ?? eq.lastKnownTemperature;
    void open() =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => EquipmentPage(equipmentId: eq.id)));
    return AppCard(
      onTap: open,
      child: Column(children: [
        Row(children: [
          IconCircle(
              icon: health == EquipmentHealth.offline ? Icons.wifi_off_rounded : Icons.warning_amber_rounded,
              color: color,
              size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(eq.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(eq.siteName ?? '', style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          StatusBadge(label: healthLabel(health), color: color),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration:
              BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          child: Row(children: [
            Text(formatTemp(temperature), style: AppTheme.numeric(size: 18, color: color)),
            const SizedBox(width: 8),
            Expanded(child: Text(_detail(), style: Theme.of(context).textTheme.bodySmall)),
            Text(tr('viewEquipment'), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
          ]),
        ),
      ]),
    );
  }
}
