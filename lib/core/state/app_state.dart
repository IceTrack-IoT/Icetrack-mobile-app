import 'package:flutter/widgets.dart';

import '../../monitoring/application/monitoring_store.dart';
import '../../notifications/domain/app_notification.dart';
import '../../service_requests/application/service_request_store.dart';
import '../../shared/data/mock_data.dart';

/// In-memory UI state: language, technician name, simulated offline switch and
/// (still mock) notifications. Backend data lives in the stores of each context.
class AppState extends ChangeNotifier {
  AppState._();

  static final AppState instance = AppState._();

  String languageCode = 'es';
  /// Filled from the technician profile after sign-in (Profiles context).
  String technicianName = '';
  String technicianSpeciality = '';
  /// "Simulate offline" switch (profile): forces the offline path of US-31 for demos.
  bool isOffline = false;
  bool isAlertPushEnabled = true;
  bool isAssignmentPushEnabled = true;

  final List<AppNotification> notifications = MockData.notifications();

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  String get technicianInitials {
    final parts = technicianName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    final last = parts.length > 1 ? parts[1][0] : '';
    return (parts.first[0] + last).toUpperCase();
  }

  void setTechnician({required String name, required String speciality}) {
    technicianName = name;
    technicianSpeciality = speciality;
    notifyListeners();
  }

  void clearTechnician() {
    technicianName = '';
    technicianSpeciality = '';
    notifyListeners();
  }

  void setLanguage(String code) {
    languageCode = code;
    notifyListeners();
  }

  void setOffline(bool value) {
    isOffline = value;
    notifyListeners();
    if (!value) ServiceRequestStore.instance.syncNow();
  }

  void setAlertPush(bool value) {
    isAlertPushEnabled = value;
    notifyListeners();
  }

  void setAssignmentPush(bool value) {
    isAssignmentPushEnabled = value;
    notifyListeners();
  }

  void markAsRead(AppNotification notification) {
    notification.isRead = true;
    notifyListeners();
  }

  void markAllAsRead() {
    for (final n in notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }
}

/// Rebuilds its child whenever the UI state, the service requests or the alerts change.
final Listenable _listenable = Listenable.merge([AppState.instance, ServiceRequestStore.instance, MonitoringStore.instance]);

class Watch extends StatelessWidget {
  const Watch({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: _listenable, builder: (context, _) => builder(context));
  }
}
