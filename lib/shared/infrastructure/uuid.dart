import 'dart:math';

/// Random UUID version 4, used as `client_generated_id` so a queued
/// intervention can be replayed without creating duplicates (US-31, RNF-07).
String uuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// ISO 8601 instant in UTC with a trailing `Z`, without fractions of a second,
/// as the backend expects for `started_at` / `completed_at`.
String isoUtc(DateTime moment) {
  final utc = moment.toUtc();
  final trimmed = DateTime.utc(utc.year, utc.month, utc.day, utc.hour, utc.minute, utc.second);
  return trimmed.toIso8601String();
}

/// Parses an ISO 8601 instant coming from the backend (null-safe).
DateTime? parseInstant(Object? value) => value is String ? DateTime.tryParse(value) : null;
