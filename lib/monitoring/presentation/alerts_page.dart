import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../domain/equipment.dart';
import 'equipment_page.dart';

/// Screen 12 · Active alerts of my equipment (US-32).
class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  String _label(EquipmentHealth h) => switch (h) {
        EquipmentHealth.critical => tr('critical'),
        EquipmentHealth.warning => tr('warningLabel'),
        EquipmentHealth.offline => tr('offlineLabel'),
        EquipmentHealth.normal => tr('inRange'),
      };

  @override
  Widget build(BuildContext context) {
    return Watch(builder: (context) {
      final app = AppState.instance;
      final text = Theme.of(context).textTheme;
      int count(EquipmentHealth h) => app.alerts.where((a) => a.health == h).length;
      return SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(24, 16, 24, 24), children: [
          Text(tr('activeAlerts'), style: text.headlineSmall),
          Text(tr('activeAlertsSub'), style: text.bodyMedium?.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 16),
          Row(children: [
            for (final h in [EquipmentHealth.critical, EquipmentHealth.warning, EquipmentHealth.offline]) ...[
              Expanded(
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${count(h)}', style: AppTheme.numeric(size: 28, color: healthColor(h))),
                    Text(_label(h), style: text.bodySmall),
                  ]),
                ),
              ),
              if (h != EquipmentHealth.offline) const SizedBox(width: 10),
            ],
          ]),
          const SizedBox(height: 16),
          for (final alert in app.alerts) ...[
            _AlertCard(alert: alert, label: _label(alert.health)),
            const SizedBox(height: 12),
          ],
        ]),
      );
    });
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.label});

  final EquipmentAlert alert;
  final String label;

  @override
  Widget build(BuildContext context) {
    final eq = AppState.instance.equipment[alert.equipmentId]!;
    final color = healthColor(alert.health);
    void open() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EquipmentPage(equipmentId: eq.id)));
    return AppCard(
      onTap: open,
      child: Column(children: [
        Row(children: [
          IconCircle(icon: alert.health == EquipmentHealth.offline ? Icons.wifi_off_rounded : Icons.warning_amber_rounded, color: color, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(eq.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(eq.siteName, style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          StatusBadge(label: label, color: color),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          child: Row(children: [
            Text(formatTemp(eq.temperature), style: AppTheme.numeric(size: 18, color: color)),
            const SizedBox(width: 8),
            Expanded(child: Text(alert.detail, style: Theme.of(context).textTheme.bodySmall)),
            Text(tr('viewEquipment'), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
          ]),
        ),
      ]),
    );
  }
}
