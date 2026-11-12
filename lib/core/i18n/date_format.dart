import '../state/app_state.dart';

const _monthsEs = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
const _monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _two(int n) => n.toString().padLeft(2, '0');

/// Local time `HH:mm` (the backend sends UTC instants).
String formatTime(DateTime? moment) {
  if (moment == null) return '—';
  final local = moment.toLocal();
  return '${_two(local.hour)}:${_two(local.minute)}';
}

/// Date and time in the technician's local time, for example `11 nov · 09:42`.
String formatDateTime(DateTime? moment) {
  if (moment == null) return '—';
  final local = moment.toLocal();
  final months = AppState.instance.languageCode == 'en' ? _monthsEn : _monthsEs;
  return '${local.day} ${months[local.month - 1]} · ${formatTime(local)}';
}
