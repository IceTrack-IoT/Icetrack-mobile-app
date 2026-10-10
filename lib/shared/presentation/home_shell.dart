import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../monitoring/presentation/alerts_page.dart';
import '../../notifications/presentation/notifications_page.dart';
import '../../profiles/presentation/profile_page.dart';
import '../../service_requests/presentation/orders_page.dart';

/// Bottom navigation: Orders · Alerts · Notices · Profile.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Watch(builder: (context) {
      final unread = AppState.instance.unreadCount;
      return Scaffold(
        body: IndexedStack(index: _index, children: const [
          OrdersPage(),
          AlertsPage(),
          NotificationsPage(),
          ProfilePage(),
        ]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            NavigationDestination(icon: const Icon(Icons.assignment_outlined), selectedIcon: const Icon(Icons.assignment), label: tr('tabOrders')),
            NavigationDestination(icon: const Icon(Icons.warning_amber_outlined), selectedIcon: const Icon(Icons.warning_amber), label: tr('tabAlerts')),
            NavigationDestination(
              icon: Badge(isLabelVisible: unread > 0, backgroundColor: AppColors.danger, label: Text('$unread'), child: const Icon(Icons.notifications_outlined)),
              selectedIcon: Badge(isLabelVisible: unread > 0, backgroundColor: AppColors.danger, label: Text('$unread'), child: const Icon(Icons.notifications)),
              label: tr('tabNotices'),
            ),
            NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: tr('tabProfile')),
          ],
        ),
      );
    });
  }
}
