import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../service_requests/domain/service_order.dart';
import '../../service_requests/presentation/intervention_page.dart';
import '../../service_requests/presentation/order_detail_page.dart';
import '../domain/equipment.dart';

/// Screen 06 · Equipment and telemetry in the field (US-33, US-32).
class EquipmentPage extends StatelessWidget {
  const EquipmentPage({super.key, required this.equipmentId});

  final String equipmentId;

  @override
  Widget build(BuildContext context) {
    return Watch(builder: (context) {
      final app = AppState.instance;
      final eq = app.equipment[equipmentId]!;
      final text = Theme.of(context).textTheme;
      final color = healthColor(eq.health);
      ServiceOrder? order;
      for (final o in app.orders) {
        if (o.equipmentId == eq.id && o.status != OrderStatus.rejected) order = o;
      }
      final linked = order;
      return Scaffold(
        appBar: AppBar(title: Text(eq.name)),
        body: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 24), children: [
          if (eq.health == EquipmentHealth.critical) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.08),
                border: Border.all(color: AppColors.danger.withOpacity(0.35)),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Row(children: [
                const IconCircle(icon: Icons.warning_amber_rounded, color: AppColors.danger, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tr('criticalAlert'), style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                    Text(tr('activeSince'), style: text.bodySmall?.copyWith(color: AppColors.textMain)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 14),
          ],
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(tr('currentTemp').toUpperCase(), style: AppTheme.badge(AppColors.textMuted))),
                if (eq.isOutOfRange) StatusBadge(label: tr('outOfRange'), color: AppColors.danger),
                if (eq.health == EquipmentHealth.offline) StatusBadge(label: tr('noSignal'), color: AppColors.offline),
              ]),
              const SizedBox(height: 6),
              Text(formatTemp(eq.temperature), style: AppTheme.numeric(size: 34, color: color)),
              Text('${tr('threshold')} ${formatTemp(eq.threshold)} · ${tr('lastReading')} ${eq.lastReading}', style: text.bodySmall),
              const SizedBox(height: 12),
              SizedBox(height: 110, width: double.infinity, child: CustomPaint(painter: TemperatureChartPainter(eq.readings, eq.threshold))),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                for (final h in ['06:00', '07:00', '08:00', '09:00', '09:41'])
                  Text(h, style: AppTheme.numeric(size: 11, color: AppColors.textSubtle)),
              ]),
            ]),
          ),
          const SizedBox(height: 14),
          Row(children: [
            _Kpi(value: '${eq.powerKw.toStringAsFixed(1)} kW', label: tr('power')),
            const SizedBox(width: 10),
            _Kpi(value: '${eq.energyKwh.toStringAsFixed(1)} kWh', label: tr('energyToday')),
            const SizedBox(width: 10),
            _Kpi(value: eq.isDoorOpen ? tr('doorOpen') : tr('doorClosed'), label: tr('door')),
          ]),
          const SizedBox(height: 18),
          SectionTitle(tr('pastInterventions')),
          const SizedBox(height: 10),
          AppCard(
            child: Column(children: [
              for (final h in eq.history)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const IconCircle(icon: Icons.build_outlined, color: AppColors.primary, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${h.date} · ${h.type}', style: AppTheme.numeric()),
                        Text(h.summary, style: text.bodySmall),
                      ]),
                    ),
                  ]),
                ),
              if (eq.history.isEmpty) Text('—', style: text.bodySmall),
            ]),
          ),
        ]),
        bottomNavigationBar: linked == null
            ? null
            : Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
                child: SafeArea(
                  top: false,
                  child: Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderDetailPage(code: linked.code))),
                        child: Text(tr('order')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: linked.status == OrderStatus.inProgress
                            ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => InterventionPage(orderCode: linked.code)))
                            : null,
                        child: Text(tr('registerIntervention'), textAlign: TextAlign.center),
                      ),
                    ),
                  ]),
                ),
              ),
      );
    });
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: AppTheme.numeric()),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }
}

/// Simple line chart: blue while in range, red once above the threshold.
class TemperatureChartPainter extends CustomPainter {
  TemperatureChartPainter(this.readings, this.threshold);

  final List<double> readings;
  final double threshold;

  @override
  void paint(Canvas canvas, Size size) {
    if (readings.length < 2) return;
    final values = [...readings, threshold];
    final minV = values.reduce((a, b) => a < b ? a : b) - 1;
    final maxV = values.reduce((a, b) => a > b ? a : b) + 1;
    double y(double v) => size.height - (v - minV) / (maxV - minV) * size.height;
    final ty = y(threshold);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, ty), Paint()..color = AppColors.danger.withOpacity(0.06));
    final dash = Paint()
      ..color = AppColors.textSubtle
      ..strokeWidth = 1.5;
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, ty), Offset(x + 5, ty), dash);
    }
    final step = size.width / (readings.length - 1);
    for (var i = 0; i < readings.length - 1; i++) {
      final a = Offset(i * step, y(readings[i]));
      final b = Offset((i + 1) * step, y(readings[i + 1]));
      final hot = readings[i + 1] > threshold;
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = hot ? AppColors.danger : AppColors.accent
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }
    final last = Offset(size.width, y(readings.last));
    canvas.drawCircle(last, 4, Paint()..color = readings.last > threshold ? AppColors.danger : AppColors.accent);
  }

  @override
  bool shouldRepaint(covariant TemperatureChartPainter oldDelegate) => oldDelegate.readings != readings;
}
