import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../domain/service_order.dart';
import 'order_detail_page.dart';

/// Screen 03 · Assigned orders (US-30, US-44).
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  OrderStatus? _filter;

  @override
  Widget build(BuildContext context) {
    return Watch(builder: (context) {
      final app = AppState.instance;
      final text = Theme.of(context).textTheme;
      final visible = app.orders.where((o) => o.status != OrderStatus.rejected && (_filter == null || o.status == _filter)).toList();
      return SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(24, 16, 24, 24), children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('today'), style: text.bodySmall),
                Text('${tr('hello')}, ${app.technicianName.split(' ').first}', style: text.headlineSmall),
              ]),
            ),
            const CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary,
              child: Text('CR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 16),
          const SyncBanner(),
          const SizedBox(height: 16),
          Row(children: [
            _Kpi(value: app.countByStatus(OrderStatus.pending), label: tr('pending'), color: AppColors.primary),
            const SizedBox(width: 10),
            _Kpi(value: app.countByStatus(OrderStatus.inProgress), label: tr('inProgressKpi'), color: AppColors.warning),
            const SizedBox(width: 10),
            _Kpi(value: app.orders.where((o) => o.status != OrderStatus.rejected).length, label: tr('forToday'), color: AppColors.textMain),
          ]),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              Chip2(label: tr('all'), isSelected: _filter == null, onTap: () => setState(() => _filter = null)),
              const SizedBox(width: 8),
              Chip2(label: tr('pending'), isSelected: _filter == OrderStatus.pending, onTap: () => setState(() => _filter = OrderStatus.pending)),
              const SizedBox(width: 8),
              Chip2(label: tr('accepted'), isSelected: _filter == OrderStatus.accepted, onTap: () => setState(() => _filter = OrderStatus.accepted)),
              const SizedBox(width: 8),
              Chip2(label: tr('completed'), isSelected: _filter == OrderStatus.completed, onTap: () => setState(() => _filter = OrderStatus.completed)),
            ]),
          ),
          const SizedBox(height: 16),
          for (final order in visible) ...[
            OrderCard(order: order),
            const SizedBox(height: 12),
          ],
        ]),
      );
    });
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.value, required this.label, required this.color});

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$value', style: AppTheme.numeric(size: 28, color: color)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order});

  final ServiceOrder order;

  @override
  Widget build(BuildContext context) {
    final eq = AppState.instance.equipment[order.equipmentId];
    final outOfRange = eq?.isOutOfRange ?? false;
    final text = Theme.of(context).textTheme;
    return AppCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderDetailPage(code: order.code))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(order.code, style: AppTheme.numeric(color: AppColors.textMuted))),
          PriorityBadge(priority: order.priority),
          const SizedBox(width: 8),
          OrderStatusBadge(status: order.status),
        ]),
        const SizedBox(height: 12),
        Text(order.equipmentName, style: text.titleMedium),
        Text(order.serviceType, style: text.bodyMedium?.copyWith(color: AppColors.textMuted)),
        const Divider(height: 24, color: AppColors.border),
        _Meta(icon: Icons.place_outlined, text: order.siteName),
        const SizedBox(height: 8),
        _Meta(icon: Icons.calendar_today_outlined, text: '${tr('today')}, ${order.scheduledAt}'),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.thermostat, size: 16, color: AppColors.textSubtle),
          const SizedBox(width: 8),
          Text(
            '${formatTemp(eq?.temperature)}  ·  ${outOfRange ? '${tr('threshold')} ${formatTemp(eq?.threshold)}' : tr('inRange')}',
            style: AppTheme.numeric(color: outOfRange ? AppColors.danger : AppColors.success),
          ),
        ]),
      ]),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.textSubtle),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(color: AppColors.textMuted))),
    ]);
  }
}
