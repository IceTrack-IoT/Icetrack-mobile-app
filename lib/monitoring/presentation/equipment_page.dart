import 'package:flutter/material.dart';

import '../../assets/domain/model/equipment.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/i18n/date_format.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../service_requests/application/service_request_store.dart';
import '../../service_requests/domain/model/service_request.dart';
import '../../service_requests/presentation/intervention_page.dart';
import '../../service_requests/presentation/order_detail_page.dart';
import '../../shared/presentation/error_text.dart';
import '../application/monitoring_store.dart';
import '../domain/model/alert.dart';
import '../domain/model/telemetry_point.dart';

String equipmentTypeLabel(EquipmentType type) => switch (type) {
      EquipmentType.displayCase => tr('typeDisplayCase'),
      EquipmentType.coldRoom => tr('typeColdRoom'),
      EquipmentType.refrigerator => tr('typeRefrigerator'),
      EquipmentType.other => tr('typeOther'),
    };

/// Screen 06 · Equipment and telemetry in the field (US-27, US-33).
/// Unit, last hours of temperature, open alerts and past interventions from the backend.
class EquipmentPage extends StatefulWidget {
  const EquipmentPage({super.key, required this.equipmentId});

  final int equipmentId;

  @override
  State<EquipmentPage> createState() => _EquipmentPageState();
}

class _EquipmentPageState extends State<EquipmentPage> {
  EquipmentOverview? _overview;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (AppState.instance.isOffline) {
      setState(() {
        _loading = false;
        _error ??= tr('needsConnection');
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final overview = await MonitoringStore.instance.overview(widget.equipmentId);
      if (mounted) {
        setState(() {
          _overview = overview;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overview = _overview;
    return Scaffold(
      appBar: AppBar(
        title: Text(overview?.equipment.name ?? tr('equipment')),
        bottom: _loading && overview != null
            ? const PreferredSize(preferredSize: Size.fromHeight(2), child: LinearProgressIndicator(minHeight: 2))
            : null,
      ),
      body: overview == null
          ? Center(
              child: _loading
                  ? const CircularProgressIndicator()
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_error is String ? _error as String : errorText(_error ?? ''), textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton(onPressed: _load, child: Text(tr('retry'))),
                      ]),
                    ),
            )
          : RefreshIndicator(onRefresh: _load, child: _Body(overview: overview)),
      bottomNavigationBar: _LinkedOrderBar(equipmentId: widget.equipmentId),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.overview});

  final EquipmentOverview overview;

  @override
  Widget build(BuildContext context) {
    final eq = overview.equipment;
    final text = Theme.of(context).textTheme;
    final health = overview.health;
    final color = healthColor(health);
    final excursion = overview.openAlerts.where((a) => a.type == AlertType.temperatureExcursion).toList();
    final points = overview.points;
    final lastPoint = points.isEmpty ? null : points.last;
    final doorSeconds = points.fold<int>(0, (sum, p) => sum + p.doorOpenSeconds);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Text('${equipmentTypeLabel(eq.type)} · ${eq.siteName ?? ''}', style: text.bodyMedium?.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 12),
        if (excursion.isNotEmpty) ...[
          _AlertBanner(alert: excursion.first),
          const SizedBox(height: 14),
        ],
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(tr('currentTemp').toUpperCase(), style: AppTheme.badge(AppColors.textMuted))),
              if (eq.underMaintenance)
                StatusBadge(label: tr('underMaintenance'), color: AppColors.warning)
              else if (eq.isSilent)
                StatusBadge(label: tr('noSignal'), color: AppColors.offline)
              else if (eq.isOutOfRange)
                StatusBadge(label: tr('outOfRange'), color: AppColors.danger),
            ]),
            const SizedBox(height: 6),
            Text(formatTemp(eq.lastKnownTemperature), style: AppTheme.numeric(size: 34, color: color)),
            Text(
              '${tr('range')} ${formatTemp(eq.minCelsius)} – ${formatTemp(eq.maxCelsius)} · '
              '${tr('lastReading')} ${formatDateTime(eq.lastReadingAt)}',
              style: text.bodySmall,
            ),
            const SizedBox(height: 12),
            if (points.length < 2)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text(tr('noTelemetry'), style: text.bodySmall)),
              )
            else ...[
              SizedBox(
                height: 120,
                width: double.infinity,
                child: CustomPaint(painter: TemperatureChartPainter(points, eq.minCelsius, eq.maxCelsius)),
              ),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                for (final p in [points.first, points[points.length ~/ 2], points.last])
                  Text(formatTime(p.start), style: AppTheme.numeric(size: 11, color: AppColors.textSubtle)),
              ]),
              const SizedBox(height: 4),
              Text(tr('lastHours').replaceFirst('{h}', '${MonitoringStore.historyHours}'), style: text.bodySmall),
            ],
          ]),
        ),
        const SizedBox(height: 14),
        Row(children: [
          _Kpi(
            value: lastPoint?.avgHumidity == null ? '—' : '${lastPoint!.avgHumidity!.toStringAsFixed(0)} %',
            label: tr('humidity'),
          ),
          const SizedBox(width: 10),
          _Kpi(value: '${(doorSeconds / 60).round()} min', label: tr('doorOpenTime')),
          const SizedBox(width: 10),
          _Kpi(value: '${overview.openAlerts.length}', label: tr('openAlerts')),
        ]),
        const SizedBox(height: 18),
        SectionTitle(tr('pastInterventions')),
        const SizedBox(height: 10),
        AppCard(
          child: Column(children: [
            for (final h in overview.interventions.take(5))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const IconCircle(icon: Icons.build_outlined, color: AppColors.primary, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${formatDateTime(h.completedAt)} · OS-${h.serviceRequestId}', style: AppTheme.numeric()),
                      Text(h.diagnosis, style: text.bodySmall?.copyWith(color: AppColors.textMain)),
                      Text(h.actionsTaken, style: text.bodySmall),
                    ]),
                  ),
                ]),
              ),
            if (overview.interventions.isEmpty) Text('—', style: text.bodySmall),
          ]),
        ),
      ],
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.alert});

  final Alert alert;

  @override
  Widget build(BuildContext context) {
    final peak = alert.peakTemperature ?? alert.triggeringTemperature;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(children: [
        const IconCircle(icon: Icons.warning_amber_rounded, color: AppColors.danger, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('criticalAlert'), style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
            Text(
              '${tr('openedAt')} ${formatDateTime(alert.openedAt)}${peak == null ? '' : ' · ${tr('peak')} ${formatTemp(peak)}'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMain),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// Shortcut to the active order of this unit, if the technician has one.
class _LinkedOrderBar extends StatelessWidget {
  const _LinkedOrderBar({required this.equipmentId});

  final int equipmentId;

  @override
  Widget build(BuildContext context) {
    return Watch(builder: (context) {
      ServiceRequest? linked;
      for (final r in ServiceRequestStore.instance.requests) {
        if (r.equipmentId == equipmentId && r.isActive) linked = r;
      }
      final order = linked;
      if (order == null) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
        child: SafeArea(
          top: false,
          child: Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => OrderDetailPage(requestId: order.id))),
                child: Text('${tr('order')} ${order.code}'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: order.status == ServiceStatus.inProgress
                    ? () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => InterventionPage(requestId: order.id)))
                    : null,
                child: Text(tr('registerIntervention'), textAlign: TextAlign.center),
              ),
            ),
          ]),
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

/// Line chart of the average temperature: blue inside the accepted range,
/// red outside it; dashed lines mark the minimum and maximum of the unit.
class TemperatureChartPainter extends CustomPainter {
  TemperatureChartPainter(this.points, this.minCelsius, this.maxCelsius);

  final List<TelemetryPoint> points;
  final double minCelsius;
  final double maxCelsius;

  bool _out(double v) => v > maxCelsius || v < minCelsius;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final values = [...points.map((p) => p.avgTemperature), minCelsius, maxCelsius];
    final minV = values.reduce((a, b) => a < b ? a : b) - 1;
    final maxV = values.reduce((a, b) => a > b ? a : b) + 1;
    double y(double v) => size.height - (v - minV) / (maxV - minV) * size.height;
    final topY = y(maxCelsius);
    final bottomY = y(minCelsius);

    final outside = Paint()..color = AppColors.danger.withValues(alpha: 0.06);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, topY), outside);
    canvas.drawRect(Rect.fromLTWH(0, bottomY, size.width, size.height - bottomY), outside);
    final dash = Paint()
      ..color = AppColors.textSubtle
      ..strokeWidth = 1.5;
    for (final lineY in [topY, bottomY]) {
      for (double x = 0; x < size.width; x += 10) {
        canvas.drawLine(Offset(x, lineY), Offset(x + 5, lineY), dash);
      }
    }

    final start = points.first.start.millisecondsSinceEpoch.toDouble();
    final span = (points.last.start.millisecondsSinceEpoch - start).toDouble();
    double x(TelemetryPoint p) => span == 0 ? 0 : (p.start.millisecondsSinceEpoch - start) / span * size.width;
    for (var i = 0; i < points.length - 1; i++) {
      final a = Offset(x(points[i]), y(points[i].avgTemperature));
      final b = Offset(x(points[i + 1]), y(points[i + 1].avgTemperature));
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = _out(points[i + 1].avgTemperature) ? AppColors.danger : AppColors.accent
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }
    final last = points.last;
    canvas.drawCircle(Offset(x(last), y(last.avgTemperature)), 4,
        Paint()..color = _out(last.avgTemperature) ? AppColors.danger : AppColors.accent);
  }

  @override
  bool shouldRepaint(covariant TemperatureChartPainter oldDelegate) => oldDelegate.points != points;
}
