import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../monitoring/presentation/equipment_page.dart';
import '../../shared/presentation/app_navigator.dart';
import '../application/notification_store.dart';
import '../infrastructure/push_messaging.dart';
import 'notifications_page.dart';

/// Connects the push events of [NotificationStore] with the screens:
/// a banner while the app is open and navigation when a push is tapped.
void attachPushPresentation() {
  final store = NotificationStore.instance;
  store.onForegroundPush = _showBanner;
  store.onPushOpened = _openFromPush;
}

Timer? _bannerTimer;

void _showBanner(PushMessage message) {
  final messenger = appMessengerKey.currentState;
  if (messenger == null) return;
  _bannerTimer?.cancel();
  messenger
    ..hideCurrentMaterialBanner()
    ..showMaterialBanner(MaterialBanner(
      backgroundColor: AppColors.surface,
      leading: const IconCircle(icon: Icons.ac_unit, color: AppColors.primaryDeep, size: 38),
      content: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(tr('pushNow'), style: AppTheme.badge(AppColors.textMuted)),
        Text(message.title ?? 'IceTrack', style: const TextStyle(fontWeight: FontWeight.w600)),
        if (message.body != null) Text(message.body!),
      ]),
      actions: [
        TextButton(onPressed: messenger.hideCurrentMaterialBanner, child: Text(tr('notNow'))),
        TextButton(
          onPressed: () {
            messenger.hideCurrentMaterialBanner();
            _openFromPush(message);
          },
          child: Text(tr('open')),
        ),
      ],
    ));
  _bannerTimer = Timer(const Duration(seconds: 8), () => appMessengerKey.currentState?.hideCurrentMaterialBanner());
}

/// The push only carries ids, so the notice is read from the backend to know its order or unit.
Future<void> _openFromPush(PushMessage message) async {
  final navigator = appNavigatorKey.currentState;
  if (navigator == null) return;
  final store = NotificationStore.instance;
  final id = message.notificationId;
  if (id != null) {
    try {
      final notification = await store.load(id);
      await store.markRead(notification);
      openNotificationTarget(navigator, notification);
      return;
    } catch (_) {
      // Fall back to the unit in the push data.
    }
  }
  if (message.equipmentId != null) {
    navigator.push(MaterialPageRoute(builder: (_) => EquipmentPage(equipmentId: message.equipmentId!)));
  }
}
