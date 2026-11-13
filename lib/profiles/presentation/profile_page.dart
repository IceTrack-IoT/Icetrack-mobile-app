import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../core/i18n/date_format.dart';
import '../../iam/application/auth_service.dart';
import '../../iam/presentation/sign_in_page.dart';
import '../../notifications/application/notification_store.dart';
import '../../service_requests/application/service_request_store.dart';
import '../../shared/presentation/error_text.dart';
import 'edit_profile_page.dart';

/// Screen 10: Profile, language and sync (US-23, US-46).
/// Also hosts the demo trigger for the expired session screen (11).
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _signOut(BuildContext context) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    await AuthService.instance.signOut();
    navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const SignInPage()), (_) => false);
  }

  Future<void> _enablePush(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await NotificationStore.instance.enablePush();
      if (!NotificationStore.instance.pushAllowed) {
        messenger.showSnackBar(SnackBar(content: Text(tr('pushDeniedHint'))));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorText(e))));
    }
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
            ServiceRequestStore.instance.syncNow();
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
      final store = ServiceRequestStore.instance;
      final notifications = NotificationStore.instance;
      final text = Theme.of(context).textTheme;
      return SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(24, 16, 24, 24), children: [
          Text(tr('profile'), style: text.headlineSmall),
          const SizedBox(height: 14),
          AppCard(
            child: Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary,
                child: Text(app.technicianInitials,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(app.technicianName, style: text.titleMedium),
                  Text('${tr('technician')} · ${app.technicianSpeciality}', style: text.bodyMedium?.copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Text(AuthService.instance.profile?.email ?? '', style: text.bodySmall),
                  if ((AuthService.instance.profile?.phone ?? '').isNotEmpty)
                    Text(AuthService.instance.profile!.phone, style: text.bodySmall),
                  if ((AuthService.instance.profile?.certificationNumber ?? '').isNotEmpty)
                    Text('${tr('certificationNumber')}: ${AuthService.instance.profile!.certificationNumber}',
                        style: text.bodySmall),
                ]),
              ),
              IconButton(
                tooltip: tr('editProfile'),
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                onPressed: AuthService.instance.profile == null
                    ? null
                    : () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => EditProfilePage(profile: AuthService.instance.profile!))),
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
              KeyValueRow(icon: Icons.cloud_outlined, label: tr('pendingRecords'), value: '${store.pending.length} ${tr('interventions')}', isNumeric: true),
              const SizedBox(height: 14),
              KeyValueRow(icon: Icons.schedule, label: tr('lastSync'), value: formatTime(store.lastSync), isNumeric: true),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(tr('simulateOffline')),
                value: app.isOffline,
                onChanged: app.setOffline,
              ),
              OutlinedButton(
                onPressed: app.isOffline || store.isLoading ? null : store.syncNow,
                child: Text(tr('syncNow')),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          SectionTitle(tr('push')),
          const SizedBox(height: 10),
          AppCard(
            child: Row(children: [
              IconCircle(
                icon: notifications.pushAllowed ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
                color: notifications.pushAllowed ? AppColors.success : AppColors.offline,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(notifications.pushAllowed ? tr('pushOn') : tr('pushOff'),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(tr('pushScope'), style: text.bodySmall),
                ]),
              ),
              if (!notifications.pushAllowed)
                TextButton(onPressed: () => _enablePush(context), child: Text(tr('enable'))),
            ]),
          ),
          const SizedBox(height: 18),
          SectionTitle(tr('demo')),
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
