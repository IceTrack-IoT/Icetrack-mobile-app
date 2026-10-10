import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../monitoring/presentation/equipment_page.dart';
import '../domain/service_order.dart';
import 'intervention_page.dart';

/// Screens 04 and 05 · Order detail, acceptance and arrival (US-30, US-33).
class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key, required this.code});

  final String code;

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Watch(builder: (context) {
      final app = AppState.instance;
      final order = app.orderByCode(code)!;
      final eq = app.equipment[order.equipmentId];
      final text = Theme.of(context).textTheme;
      return Scaffold(
        appBar: AppBar(title: Text('${tr('order')} ${order.code}')),
        body: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 24), children: [
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [PriorityBadge(priority: order.priority), const SizedBox(width: 8), OrderStatusBadge(status: order.status)]),
              const SizedBox(height: 8),
              Text(order.equipmentName, style: text.headlineSmall),
              Text(order.serviceType, style: text.bodyMedium?.copyWith(color: AppColors.textMuted)),
            ]),
          ),
          const SizedBox(height: 14),
          SectionTitle(tr('orderStatus')),
          const SizedBox(height: 10),
          StatusStepper(status: order.status),
          const SizedBox(height: 14),
          AppCard(
            child: Column(children: [
              KeyValueRow(icon: Icons.place_outlined, label: tr('site'), value: '${order.siteName} · ${order.address}'),
              const SizedBox(height: 14),
              KeyValueRow(icon: Icons.calendar_today_outlined, label: tr('scheduled'), value: '${tr('today')} · ${order.scheduledAt}', isNumeric: true),
              const SizedBox(height: 14),
              KeyValueRow(icon: Icons.person_outline, label: tr('requestedBy'), value: '${order.requestedBy} · ${tr('owner')}'),
              if (order.status == OrderStatus.accepted) ...[
                const SizedBox(height: 14),
                KeyValueRow(icon: Icons.schedule, label: tr('eta'), value: '10:22 a. m.', isNumeric: true),
                const SizedBox(height: 14),
                KeyValueRow(icon: Icons.phone_outlined, label: tr('contact'), value: order.contactPhone, isNumeric: true),
              ],
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('reportedIssue').toUpperCase(), style: AppTheme.badge(AppColors.textMuted)),
                  const SizedBox(height: 6),
                  Text(order.reportedIssue),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          if (eq != null)
            AppCard(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EquipmentPage(equipmentId: eq.id))),
              child: Row(children: [
                IconCircle(icon: Icons.thermostat, color: eq.isOutOfRange ? AppColors.danger : AppColors.success, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tr('currentTemp'), style: text.bodySmall),
                    Text(formatTemp(eq.temperature),
                        style: AppTheme.numeric(size: 20, color: eq.isOutOfRange ? AppColors.danger : AppColors.success)),
                    Text('${tr('threshold')} ${formatTemp(eq.threshold)} · ${eq.lastReading}', style: text.bodySmall),
                  ]),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSubtle),
              ]),
            ),
        ]),
        bottomNavigationBar: _ActionBar(order: order, onMessage: (m) => _snack(context, m)),
      );
    });
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.order, required this.onMessage});

  final ServiceOrder order;
  final ValueChanged<String> onMessage;

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    Widget? content;
    switch (order.status) {
      case OrderStatus.pending:
        content = Row(children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
              onPressed: () {
                app.rejectOrder(order);
                onMessage(tr('orderRejectedMsg'));
                Navigator.of(context).pop();
              },
              child: Text(tr('reject')),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: () {
                app.acceptOrder(order);
                onMessage(tr('orderAcceptedMsg'));
              },
              child: Text(tr('acceptService')),
            ),
          ),
        ]);
      case OrderStatus.accepted:
        content = Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr('arrivedQuestion'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          FilledButton(onPressed: () => app.startService(order), child: Text(tr('arrived'))),
        ]);
      case OrderStatus.inProgress:
        content = FilledButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => InterventionPage(orderCode: order.code))),
          child: Text(tr('registerIntervention')),
        );
      case OrderStatus.completed:
      case OrderStatus.rejected:
        content = null;
    }
    if (content == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(top: false, child: content),
    );
  }
}
