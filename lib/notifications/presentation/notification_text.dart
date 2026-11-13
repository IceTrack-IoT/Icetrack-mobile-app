import '../../core/i18n/app_strings.dart';
import '../../core/widgets/widgets.dart';
import '../domain/model/app_notification.dart';

/// Title and body of a notice in the app language, built from the template
/// (`message_key` + `message_params`). Unknown keys fall back to the backend text (English).
(String, String) notificationText(AppNotification n) {
  final p = n.params;
  String param(String key) => '${p[key] ?? ''}';
  final equipment = param('equipment_name');
  final order = 'OS-${p['service_request_id'] ?? n.serviceRequestId ?? ''}';

  String fill(String key, Map<String, String> values) {
    var text = tr(key);
    values.forEach((name, value) => text = text.replaceAll('{$name}', value));
    return text;
  }

  switch (n.messageKey) {
    case 'alert.temperature_excursion.raised':
      final temperature = double.tryParse(param('temperature'));
      final threshold = double.tryParse(param('threshold'));
      return (
        fill('ntfExcursionTitle', {'equipment': equipment}),
        fill(param('limit') == 'MIN' ? 'ntfExcursionBodyMin' : 'ntfExcursionBodyMax',
            {'temperature': formatTemp(temperature), 'threshold': formatTemp(threshold)}),
      );
    case 'alert.device_offline.raised':
      return (
        fill('ntfOfflineTitle', {'equipment': equipment}),
        fill('ntfOfflineBody', {'minutes': param('silent_minutes')}),
      );
    case 'alert.sensor_failure.raised':
      return (fill('ntfSensorTitle', {'equipment': equipment}), tr('ntfSensorBody'));
    case 'service_request.assigned':
      return (fill('ntfAssignedTitle', {'order': order}), equipment);
    case 'service_request.unassigned':
      return (fill('ntfUnassignedTitle', {'order': order}), fill('ntfUnassignedBody', {'equipment': equipment}));
    case 'service_request.rejected':
      return (
        fill('ntfRejectedTitle', {'order': order}),
        fill('ntfReasonBody', {'equipment': equipment, 'reason': param('reason')}),
      );
    case 'service_request.canceled':
      return (
        fill('ntfCanceledTitle', {'order': order}),
        fill('ntfReasonBody', {'equipment': equipment, 'reason': param('reason')}),
      );
    case 'maintenance_window.opened':
      return (
        tr('ntfWindowOpenedTitle'),
        fill(param('origin') == 'BUTTON' ? 'ntfWindowOpenedButton' : 'ntfWindowOpenedApp', {'equipment': equipment}),
      );
    case 'maintenance_window.closed':
      return (tr('ntfWindowClosedTitle'), equipment);
  }
  return (tr('ntfGenericTitle'), n.fallbackMessage);
}
