import 'dart:convert';

/// Error raised by any backend call. Mirrors the backend error contract
/// `{ code, message, details }` (and the refresh `AuthErrorResource`, which also has `code`).
class ApiException implements Exception {
  const ApiException({required this.statusCode, this.code, this.message, this.details});

  /// No connection, DNS failure or timeout: the request never got an answer.
  const ApiException.network()
      : statusCode = 0,
        code = 'NETWORK_ERROR',
        message = null,
        details = null;

  factory ApiException.fromResponse(int statusCode, String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return ApiException(
          statusCode: statusCode,
          code: decoded['code'] as String?,
          message: decoded['message'] as String?,
          details: decoded['details'] as String?,
        );
      }
    } on FormatException {
      // Empty or non-JSON body (e.g. 401 with no content).
    }
    return ApiException(statusCode: statusCode);
  }

  final int statusCode;
  final String? code;
  final String? message;
  final String? details;

  bool get isNetwork => statusCode == 0;
  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;

  @override
  String toString() => 'ApiException($statusCode, $code, $message, $details)';
}
