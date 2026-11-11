import '../../core/i18n/app_strings.dart';
import '../infrastructure/api_exception.dart';

/// Turns a backend error into a message for the technician.
/// Branches on `code` (never on `message`), as the backend error contract asks.
String errorText(Object error) {
  if (error is! ApiException) return tr('errorUnexpected');
  if (error.isNetwork) return tr('errorNetwork');
  switch (error.code) {
    case 'BAD_CREDENTIALS':
    case 'INVALID_TOKEN':
      return tr('errorBadCredentials');
    case 'ROLE_CHANNEL_MISMATCH':
      return tr('errorChannel');
    case 'TOO_MANY_REQUESTS':
      return tr('errorTooMany');
    case 'USER_CONFLICT':
      return tr('errorUserConflict');
    case 'PROFILE_CONFLICT':
    case 'TECHNICIAN_CONFLICT':
      return tr('errorProfileConflict');
    case 'VALIDATION_ERROR':
      return error.details ?? error.message ?? tr('errorUnexpected');
  }
  if (error.statusCode >= 500) {
    return '${tr('errorServer')}${error.details != null ? ' (${error.details})' : ''}';
  }
  return error.message ?? tr('errorUnexpected');
}
