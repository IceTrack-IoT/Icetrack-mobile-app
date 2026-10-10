import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../monitoring/presentation/equipment_page.dart';
import '../../service_requests/presentation/order_detail_page.dart';
import '../domain/app_notification.dart';

/// Screen 09 · Notification center filtered by role (US-43, US-44).
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _onlyUnread = false;

  void _open(AppNotification n) {
    AppState.instance.markAsRead(n);
    final target = n.targetId;
    if (target == null) return;
    final route = n.kind == NotificationKind.alert
        ? MaterialPageRoute(builder: (_) => EquipmentPage(equipmentId: target))
        : MaterialPageRoute(builder: (_) => OrderDetailPage(code: target));
    Navigator.of(context).push(route);
  }

  @override
  Widget build(BuildContext context) {
    return Watch(builder: (context) {
      final app = AppState.instance;
      final items = app.notifications.where((n) => !_onlyUnread || !n.isRead).toList();
      final today = items.where((n) => n.isToday).toList();
      final older = items.where((n) => !n.isToday).toList();
      return SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(24, 16, 24, 24), children: [
          Text(tr('notifications'), style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Row(children: [
            Chip2(label: tr('all'), isSelected: !_onlyUnread, onTap: () => setState(() => _onlyUnread = false)),
            const SizedBox(width: 8),
            Chip2(label: '${tr('unread')} · ${app.unreadCount}', isSelected: _onlyUnread, onTap: () => setState(() => _onlyUnread = true)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
            child: Row(children: [
              const Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(tr('roleNotice'), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primaryDark))),
            ]),
          ),
          const SizedBox(height: 16),
          if (today.isNotEmpty) ...[
            SectionTitle(tr('today'), action: tr('markAllRead'), onAction: app.markAllAsRead),
            const SizedBox(height: 10),
            _Group(items: today, onTap: _open),
            const SizedBox(height: 16),
          ],
          if (older.isNotEmpty) ...[
            SectionTitle(tr('yesterday')),
            const SizedBox(height: 10),
            _Group(items: older, onTap: _open),
          ],
        ]),
      );
    });
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.items, required this.onTap});

  final List<AppNotification> items;
  final ValueChanged<AppNotification> onTap;

  (IconData, Color) _style(NotificationKind kind) => switch (kind) {
        NotificationKind.alert => (Icons.warning_amber_rounded, AppColors.danger),
        NotificationKind.order => (Icons.assignment_outlined, AppColors.primary),
        NotificationKind.reminder => (Icons.schedule, AppColors.warning),
        NotificationKind.sync => (Icons.sync, AppColors.success),
        NotificationKind.review => (Icons.star_outline, AppColors.offline),
      };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        for (final n in items)
          InkWell(
            onTap: () => onTap(n),
            child: Container(
              color: n.isRead ? null : AppColors.primaryLight.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                IconCircle(icon: _style(n.kind).$1, color: _style(n.kind).$2, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w600)),
                    Text(n.body, style: Theme.of(context).textTheme.bodySmall),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(n.time, style: AppTheme.numeric(color: AppColors.textSubtle)),
                  if (!n.isRead) ...[
                    const SizedBox(height: 6),
                    const CircleAvatar(radius: 4, backgroundColor: AppColors.accent),
                  ],
                ]),
              ]),
            ),
          ),
      ]),
    );
  }
}
