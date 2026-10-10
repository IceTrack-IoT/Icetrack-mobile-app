import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../iam/presentation/sign_in_page.dart';
import '../../monitoring/presentation/equipment_page.dart';

/// Screen 10 · Profile, language and sync (US-23, US-46).
/// Also hosts demo triggers for the push alert (08) and expired session (11).
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _signOut(BuildContext context) {
    Navigator.of(context, rootNavigator: true)
        .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const SignInPage()), (_) => false);
  }

  void _simulatePush(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showMaterialBanner(MaterialBanner(
      backgroundColor: AppColors.surface,
      leading: const IconCircle(icon: Icons.ac_unit, color: AppColors.primaryDeep, size: 38),
      content: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('ICETRACK · ahora', style: AppTheme.badge(AppColors.textMuted)),
        Text(tr('pushTitle'), style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
        Text(tr('pushBody')),
      ]),
      actions: [
        TextButton(
          onPressed: () {
            messenger.hideCurrentMaterialBanner();
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EquipmentPage(equipmentId: 'FH-02')));
          },
          child: Text(tr('open')),
        ),
      ],
    ));
  }

  void _simulateExpired(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const IconCircle(icon: Icons.lock_outline, color: AppColors.warning, size: 56),
          const SizedBox(height: 12),
          Text(tr('sessionExpired'), style: Theme.of(sheetContext).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(tr('sessionExpiredBody'), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 14),
          const SyncBanner(),
          const SizedBox(height: 14),
          GoogleButton(label: tr('continueGoogle'), onPressed: () {
            Navigator.of(sheetContext).pop();
            AppState.instance.syncPending();
          }),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: () => Navigator.of(sheetContext).pop(), child: Text(tr('notNow'))),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Watch(builder: (context) {
      final app = AppState.instance;
      final text = Theme.of(context).textTheme;
      return SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(24, 16, 24, 24), children: [
          Text(tr('profile'), style: text.headlineSmall),
          const SizedBox(height: 14),
          AppCard(
            child: Row(children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary,
                child: Text('CR', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(app.technicianName, style: text.titleMedium),
                  Text('${tr('technician')} · ${app.companyName}', style: text.bodyMedium?.copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Text(tr('googleLinked'), style: text.bodySmall),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          SectionTitle(tr('language')),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'es', label: Text('Español (Latam)')),
              ButtonSegment(value: 'en', label: Text('English')),
            ],
            selected: {app.languageCode},
            onSelectionChanged: (s) => app.setLanguage(s.first),
          ),
          const SizedBox(height: 18),
          SectionTitle(tr('sync')),
          const SizedBox(height: 10),
          AppCard(
            child: Column(children: [
              KeyValueRow(icon: Icons.cloud_outlined, label: tr('pendingRecords'), value: '${app.pendingSync.length} ${tr('interventions')}', isNumeric: true),
              const SizedBox(height: 14),
              KeyValueRow(icon: Icons.schedule, label: tr('lastSync'), value: app.lastSync, isNumeric: true),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(tr('simulateOffline')),
                value: app.isOffline,
                onChanged: app.setOffline,
              ),
              OutlinedButton(onPressed: app.isOffline ? null : app.syncPending, child: Text(tr('syncNow'))),
            ]),
          ),
          const SizedBox(height: 18),
          SectionTitle(tr('push')),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(tr('pushAlerts')),
                subtitle: Text(tr('pushAlertsSub')),
                value: app.isAlertPushEnabled,
                onChanged: app.setAlertPush,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(tr('pushOrders')),
                subtitle: Text(tr('pushOrdersSub')),
                value: app.isAssignmentPushEnabled,
                onChanged: app.setAssignmentPush,
              ),
            ]),
          ),
          const SizedBox(height: 18),
          SectionTitle(tr('demo')),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: () => _simulatePush(context), icon: const Icon(Icons.notifications_active_outlined), label: Text(tr('simulatePush'))),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: () => _simulateExpired(context), icon: const Icon(Icons.lock_clock_outlined), label: Text(tr('simulateExpired'))),
          const SizedBox(height: 18),
          TextButton.icon(
            onPressed: () => _signOut(context),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            icon: const Icon(Icons.logout),
            label: Text(tr('signOut')),
          ),
        ]),
      );
    });
  }
}
