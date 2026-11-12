import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/i18n/date_format.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../shared/presentation/error_text.dart';
import '../application/service_request_store.dart';
import '../domain/model/service_request.dart';
import 'order_detail_page.dart';

/// Screen 03: Assigned orders (US-30, US-44), loaded from `GET /service-requests?assigned_to=me`.
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  ServiceStatus? _filter;

  @override
  void initState() {
    super.initState();
    final store = ServiceRequestStore.instance;
    if (!store.hasLoaded) store.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Watch(builder: (context) {
      final app = AppState.instance;
      final store = ServiceRequestStore.instance;
      final text = Theme.of(context).textTheme;
      final visible = store.requests.where((r) => _filter == null || r.status == _filter).toList();
      return SafeArea(
        child: RefreshIndicator(
          onRefresh: store.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tr('today'), style: text.bodySmall),
                    Text('${tr('hello')}, ${app.technicianName.split(' ').first}', style: text.headlineSmall),
                  ]),
                ),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary,
                  child: Text(app.technicianInitials,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 16),
              const SyncBanner(),
              if (store.syncIssues.isNotEmpty) ...[
                const SizedBox(height: 8),
                _SyncIssues(codes: store.syncIssues),
              ],
              if (store.loadError != null && !store.loadError!.isNetwork) ...[
                const SizedBox(height: 8),
                Text(errorText(store.loadError!), style: const TextStyle(color: AppColors.danger)),
              ],
              const SizedBox(height: 16),
              Row(children: [
                _Kpi(value: store.countBy(ServiceStatus.pending), label: tr('pending'), color: AppColors.primary),
                const SizedBox(width: 10),
                _Kpi(value: store.countBy(ServiceStatus.inProgress), label: tr('inProgressKpi'), color: AppColors.warning),
                const SizedBox(width: 10),
                _Kpi(
                    value: store.requests.where((r) => r.isActive).length,
                    label: tr('activeOrders'),
                    color: AppColors.textMain),
              ]),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  Chip2(label: tr('all'), isSelected: _filter == null, onTap: () => setState(() => _filter = null)),
                  const SizedBox(width: 8),
                  for (final entry in {
                    ServiceStatus.pending: tr('pending'),
                    ServiceStatus.accepted: tr('accepted'),
                    ServiceStatus.inProgress: tr('statusInProgress'),
                    ServiceStatus.completed: tr('completed'),
                  }.entries) ...[
                    Chip2(
                      label: entry.value,
                      isSelected: _filter == entry.key,
                      onTap: () => setState(() => _filter = entry.key),
                    ),
                    const SizedBox(width: 8),
                  ],
                ]),
              ),
              const SizedBox(height: 16),
              if (store.isLoading && !store.hasLoaded)
                const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
              else if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(tr('noOrders'), textAlign: TextAlign.center, style: text.bodyMedium),
                )
              else
                for (final request in visible) ...[
                  OrderCard(request: request),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      );
    });
  }
}

class _SyncIssues extends StatelessWidget {
  const _SyncIssues({required this.codes});

  final List<String> codes;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.warning.withValues(alpha: 0.10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        const Icon(Icons.info_outline, size: 18, color: AppColors.warning),
        const SizedBox(width: 8),
        Expanded(child: Text('${tr('syncIssue')} ${codes.join(', ')}', style: Theme.of(context).textTheme.bodySmall)),
        IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: ServiceRequestStore.instance.clearSyncIssues,
        ),
      ]),
    );
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

String serviceTypeLabel(ServiceType type) =>
    type == ServiceType.preventiveMaintenance ? tr('typePreventive') : tr('typeRepair');

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final queued = ServiceRequestStore.instance.isPendingSync(request.id);
    return AppCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderDetailPage(requestId: request.id))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(request.code, style: AppTheme.numeric(color: AppColors.textMuted))),
          PriorityBadge(priority: request.priority),
          const SizedBox(width: 8),
          queued
              ? StatusBadge(label: tr('pendingSyncBadge'), color: AppColors.offline)
              : OrderStatusBadge(status: request.status),
        ]),
        const SizedBox(height: 12),
        Text(request.equipmentName ?? '${tr('equipment')} #${request.equipmentId}', style: text.titleMedium),
        Text(serviceTypeLabel(request.type), style: text.bodyMedium?.copyWith(color: AppColors.textMuted)),
        const Divider(height: 24, color: AppColors.border),
        _Meta(icon: Icons.place_outlined, text: request.siteName ?? '—'),
        const SizedBox(height: 8),
        _Meta(icon: Icons.calendar_today_outlined, text: '${tr('requestedOn')} ${formatDateTime(request.createdAt)}'),
        if (request.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          _Meta(icon: Icons.notes_outlined, text: request.description, maxLines: 2),
        ],
      ]),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, this.maxLines});

  final IconData icon;
  final String text;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: AppColors.textSubtle),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text,
            maxLines: maxLines,
            overflow: maxLines == null ? null : TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted)),
      ),
    ]);
  }
}
