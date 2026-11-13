import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/i18n/date_format.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../monitoring/presentation/equipment_page.dart';
import '../../service_requests/presentation/order_detail_page.dart';
import '../../shared/presentation/error_text.dart';
import '../application/notification_store.dart';
import '../domain/model/app_notification.dart';
import 'notification_text.dart';

/// Opens the order or the unit a notice is about.
void openNotificationTarget(NavigatorState navigator, AppNotification n) {
  if (n.serviceRequestId != null) {
    navigator.push(MaterialPageRoute(builder: (_) => OrderDetailPage(requestId: n.serviceRequestId!)));
  } else if (n.equipmentId != null) {
    navigator.push(MaterialPageRoute(builder: (_) => EquipmentPage(equipmentId: n.equipmentId!)));
  }
}

/// Screen 09: Notification center (US-43, US-44). The backend only returns the
/// notices addressed to the signed-in technician.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _onlyUnread = false;

  @override
  void initState() {
    super.initState();
    final store = NotificationStore.instance;
    if (!store.hasLoaded) WidgetsBinding.instance.addPostFrameCallback((_) => store.refresh());
  }

  Future<void> _open(AppNotification n) async {
    final navigator = Navigator.of(context);
    try {
      await NotificationStore.instance.markRead(n);
    } catch (_) {
      // Opening the target matters more than the read mark.
    }
    openNotificationTarget(navigator, n);
  }

  Future<void> _markAll() async {
    try {
      await NotificationStore.instance.markAllRead();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Watch(builder: (context) {
      final store = NotificationStore.instance;
      final items = store.items.where((n) => !_onlyUnread || !n.isRead).toList();
      final now = DateTime.now();
      bool isToday(AppNotification n) {
        final local = n.createdAt.toLocal();
        return local.year == now.year && local.month == now.month && local.day == now.day;
      }

      final today = items.where(isToday).toList();
      final older = items.where((n) => !isToday(n)).toList();
      final text = Theme.of(context).textTheme;
      return SafeArea(
        child: RefreshIndicator(
          onRefresh: store.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              Text(tr('notifications'), style: text.headlineSmall),
              const SizedBox(height: 12),
              Row(children: [
                Chip2(label: tr('all'), isSelected: !_onlyUnread, onTap: () => setState(() => _onlyUnread = false)),
                const SizedBox(width: 8),
                Chip2(
                  label: '${tr('unread')} · ${store.unreadCount}',
                  isSelected: _onlyUnread,
                  onTap: () => setState(() => _onlyUnread = true),
                ),
                const Spacer(),
                if (store.unreadCount > 0)
                  TextButton(
                    onPressed: AppState.instance.isOffline ? null : _markAll,
                    child: Text(tr('markAllRead')),
                  ),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration:
                    BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                child: Row(children: [
                  const Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(tr('roleNotice'), style: text.bodySmall?.copyWith(color: AppColors.primaryDark)),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              if (store.loadError != null) ...[
                Text(errorText(store.loadError!), style: const TextStyle(color: AppColors.danger)),
                const SizedBox(height: 12),
              ],
              if (store.isLoading && !store.hasLoaded)
                const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
              else if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(tr('noNotifications'), textAlign: TextAlign.center, style: text.bodyMedium),
                )
              else ...[
                if (today.isNotEmpty) ...[
                  SectionTitle(tr('today')),
                  const SizedBox(height: 10),
                  _Group(items: today, onTap: _open, showDate: false),
                  const SizedBox(height: 16),
                ],
                if (older.isNotEmpty) ...[
                  SectionTitle(tr('earlier')),
                  const SizedBox(height: 10),
                  _Group(items: older, onTap: _open, showDate: true),
                ],
                const SizedBox(height: 8),
                Text(tr('swipeToDismiss'), textAlign: TextAlign.center, style: text.bodySmall),
              ],
            ],
          ),
        ),
      );
    });
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.items, required this.onTap, required this.showDate});

  final List<AppNotification> items;
  final ValueChanged<AppNotification> onTap;
  final bool showDate;

  (IconData, Color) _style(AppNotification n) {
    if (n.isAlert) {
      return n.type == NotificationType.deviceOffline
          ? (Icons.wifi_off_rounded, AppColors.offline)
          : (Icons.warning_amber_rounded, n.severity == NotificationSeverity.critical ? AppColors.danger : AppColors.warning);
    }
    return switch (n.type) {
      NotificationType.serviceRequestUpdate => (Icons.assignment_outlined, AppColors.primary),
      NotificationType.maintenanceWindow => (Icons.build_outlined, AppColors.warning),
      _ => (Icons.notifications_none, AppColors.textMuted),
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        for (final n in items)
          Dismissible(
            key: ValueKey('notification-${n.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: AppColors.offline.withValues(alpha: 0.15),
              child: const Icon(Icons.delete_outline, color: AppColors.offline),
            ),
            onDismissed: (_) => NotificationStore.instance.dismiss(n),
            child: InkWell(
              onTap: () => onTap(n),
              child: Container(
                color: n.isRead ? null : AppColors.primaryLight.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  IconCircle(icon: _style(n).$1, color: _style(n).$2, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(notificationText(n).$1,
                          style: TextStyle(fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w600)),
                      Text(notificationText(n).$2, style: Theme.of(context).textTheme.bodySmall),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(showDate ? formatDateTime(n.createdAt) : formatTime(n.createdAt),
                        style: AppTheme.numeric(size: 12, color: AppColors.textSubtle)),
                    if (!n.isRead) ...[
                      const SizedBox(height: 6),
                      const CircleAvatar(radius: 4, backgroundColor: AppColors.accent),
                    ],
                  ]),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}
