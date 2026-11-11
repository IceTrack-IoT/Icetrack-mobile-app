import 'package:flutter/material.dart';

import '../../monitoring/domain/equipment.dart';
import '../../service_requests/application/service_request_store.dart';
import '../../service_requests/domain/model/service_request.dart';
import '../i18n/date_format.dart';
import '../i18n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label.toUpperCase(), style: AppTheme.badge(color)),
      ]),
    );
  }
}

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});

  final ServiceStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case ServiceStatus.pending:
        return StatusBadge(label: tr('statusPending'), color: AppColors.accent);
      case ServiceStatus.accepted:
        return StatusBadge(label: tr('statusAccepted'), color: AppColors.success);
      case ServiceStatus.inProgress:
        return StatusBadge(label: tr('statusInProgress'), color: AppColors.warning);
      case ServiceStatus.completed:
        return StatusBadge(label: tr('statusCompleted'), color: AppColors.primary);
      case ServiceStatus.canceled:
        return StatusBadge(label: tr('statusCanceled'), color: AppColors.offline);
    }
  }
}

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});

  final ServicePriority priority;

  @override
  Widget build(BuildContext context) {
    switch (priority) {
      case ServicePriority.urgent:
        return StatusBadge(label: tr('priorityUrgent'), color: AppColors.danger);
      case ServicePriority.high:
        return StatusBadge(label: tr('priorityHigh'), color: AppColors.danger);
      case ServicePriority.medium:
        return StatusBadge(label: tr('priorityMedium'), color: AppColors.warning);
      case ServicePriority.low:
        return StatusBadge(label: tr('priorityLow'), color: AppColors.offline);
    }
  }
}

Color healthColor(EquipmentHealth health) {
  switch (health) {
    case EquipmentHealth.normal:
      return AppColors.success;
    case EquipmentHealth.warning:
      return AppColors.warning;
    case EquipmentHealth.critical:
      return AppColors.danger;
    case EquipmentHealth.offline:
      return AppColors.offline;
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(16), this.color});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class IconCircle extends StatelessWidget {
  const IconCircle({super.key, required this.icon, required this.color, this.size = 40});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.action, this.onAction});

  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Text(text, style: Theme.of(context).textTheme.titleMedium)),
      if (action != null)
        GestureDetector(
          onTap: onAction,
          child: Text(action!, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
    ]);
  }
}

class KeyValueRow extends StatelessWidget {
  const KeyValueRow({super.key, required this.icon, required this.label, required this.value, this.isNumeric = false});

  final IconData icon;
  final String label;
  final String value;
  final bool isNumeric;

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      IconCircle(icon: icon, color: AppColors.primary, size: 36),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: isNumeric ? AppTheme.numeric() : const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textMain),
          ),
        ]),
      ),
    ]);
  }
}

/// Sync state banner: offline queue (US-31) or everything synced.
class SyncBanner extends StatelessWidget {
  const SyncBanner({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final store = ServiceRequestStore.instance;
    final offline = store.isOfflineNow;
    final queued = store.pending.length;
    final color = offline || queued > 0 ? AppColors.offline : AppColors.success;
    final text = message ??
        (offline || queued > 0
            ? '${offline ? tr('noConnection') : tr('syncing')} · ${tr('offlineQueue')} $queued'
            : '${tr('allSynced')} · ${formatTime(store.lastSync)}');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(children: [
        Icon(offline ? Icons.wifi_off_rounded : Icons.check_rounded, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMain))),
      ]),
    );
  }
}

class StatusStepper extends StatelessWidget {
  const StatusStepper({super.key, required this.status});

  final ServiceStatus status;

  @override
  Widget build(BuildContext context) {
    final steps = [tr('statusPending'), tr('statusAccepted'), tr('statusInProgress'), tr('statusCompleted')];
    final current = switch (status) {
      ServiceStatus.pending || ServiceStatus.canceled => 0,
      ServiceStatus.accepted => 1,
      ServiceStatus.inProgress => 2,
      ServiceStatus.completed => 3,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (i) {
        final done = i < current || status == ServiceStatus.completed;
        final now = i == current && status != ServiceStatus.completed;
        return Expanded(
          child: Column(children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.success : (now ? AppColors.primary : AppColors.surface),
                border: done || now ? null : Border.all(color: AppColors.border, width: 2),
              ),
              child: done
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : (now ? const Center(child: CircleAvatar(radius: 4, backgroundColor: Colors.white)) : null),
            ),
            const SizedBox(height: 6),
            Text(
              steps[i],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: now ? FontWeight.w600 : FontWeight.w400,
                color: now ? AppColors.primary : (done ? AppColors.textMain : AppColors.textSubtle),
              ),
            ),
          ]),
        );
      }),
    );
  }
}

class Chip2 extends StatelessWidget {
  const Chip2({super.key, required this.label, required this.isSelected, required this.onTap, this.showCheck = false});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showCheck;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          border: isSelected ? null : Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (showCheck && isSelected) ...[
            const Icon(Icons.check, size: 14, color: Colors.white),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textMuted,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ]),
      ),
    );
  }
}

String formatTemp(double? value) {
  if (value == null) return '—';
  final text = value.abs().toStringAsFixed(1);
  return value < 0 ? '−$text °C' : '$text °C';
}
