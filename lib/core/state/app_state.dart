import 'package:flutter/widgets.dart';

import '../../monitoring/domain/equipment.dart';
import '../../notifications/domain/app_notification.dart';
import '../../service_requests/domain/service_order.dart';
import '../../shared/data/mock_data.dart';

/// Single in-memory store for the demo. Each method mirrors a future API call.
class AppState extends ChangeNotifier {
  AppState._();

  static final AppState instance = AppState._();

  String languageCode = 'es';
  String technicianName = 'Carlos Ramírez';
  String companyName = 'FrioService S.A.C.';
  bool isOffline = false;
  bool isAlertPushEnabled = true;
  bool isAssignmentPushEnabled = true;
  String lastSync = '09:38';

  final List<ServiceOrder> orders = MockData.orders();
  final Map<String, Equipment> equipment = MockData.equipment();
  final List<EquipmentAlert> alerts = MockData.alerts();
  final List<AppNotification> notifications = MockData.notifications();
  final List<Intervention> pendingSync = [];

  int _localSequence = 0x7F3A;

  ServiceOrder? orderByCode(String code) {
    for (final order in orders) {
      if (order.code == code) return order;
    }
    return null;
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  int countByStatus(OrderStatus status) => orders.where((o) => o.status == status).length;

  void setLanguage(String code) {
    languageCode = code;
    notifyListeners();
  }

  void setOffline(bool value) {
    isOffline = value;
    if (!value) syncPending();
    notifyListeners();
  }

  void setAlertPush(bool value) {
    isAlertPushEnabled = value;
    notifyListeners();
  }

  void setAssignmentPush(bool value) {
    isAssignmentPushEnabled = value;
    notifyListeners();
  }

  void acceptOrder(ServiceOrder order) => _setStatus(order, OrderStatus.accepted);

  void rejectOrder(ServiceOrder order) => _setStatus(order, OrderStatus.rejected);

  void startService(ServiceOrder order) => _setStatus(order, OrderStatus.inProgress);

  /// Returns true when sent online, false when stored in the local queue (US-31).
  bool submitIntervention(Intervention intervention) {
    final order = orderByCode(intervention.orderCode);
    if (isOffline) {
      final alreadyQueued = pendingSync.any((i) => i.orderCode == intervention.orderCode);
      if (!alreadyQueued) pendingSync.add(intervention);
      notifyListeners();
      return false;
    }
    if (order != null) order.status = OrderStatus.completed;
    notifyListeners();
    return true;
  }

  String nextLocalId() {
    _localSequence++;
    return 'INT-${_localSequence.toRadixString(16).toUpperCase()}-2C';
  }

  void syncPending() {
    if (isOffline || pendingSync.isEmpty) return;
    for (final intervention in pendingSync) {
      orderByCode(intervention.orderCode)?.status = OrderStatus.completed;
    }
    pendingSync.clear();
    lastSync = 'ahora';
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

  void _setStatus(ServiceOrder order, OrderStatus status) {
    order.status = status;
    notifyListeners();
  }
}

/// Rebuilds its child whenever [AppState] changes (language, orders, sync...).
class Watch extends StatelessWidget {
  const Watch({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: AppState.instance, builder: (context, _) => builder(context));
  }
}
