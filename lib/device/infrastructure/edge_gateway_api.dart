import 'dart:convert';

import 'package:http/http.dart' as http;

import 'resources/gateway_resources.dart';

enum GatewayErrorKind { unreachable, unauthorized, conflict, rejected }

class EdgeGatewayException implements Exception {
  const EdgeGatewayException(this.kind, [this.message]);

  final GatewayErrorKind kind;
  final String? message;

  @override
  String toString() => 'EdgeGatewayException($kind, $message)';
}

/// Local API of the Edge Service running in the client's premises. It is reached on
/// the local network, outside the cloud backend, and authorizes the technician with
/// the edge grant (`X-Edge-Grant`) issued when the order was accepted.
class EdgeGatewayApi {
  EdgeGatewayApi([http.Client? client]) : _http = client ?? http.Client();

  final http.Client _http;

  static const Duration _timeout = Duration(seconds: 8);

  /// `GET /api/v1/status`: true when the gateway answers on that address.
  Future<bool> isReachable(String baseUrl) async {
    try {
      final response = await _http.get(_uri(baseUrl, '/api/v1/status')).timeout(_timeout);
      return response.statusCode == 200;
    } on Exception {
      return false;
    }
  }

  /// Opens (`active: true`) or closes the maintenance window of the device (US-48).
  Future<GatewayDirectivesResource> setMaintenance(String baseUrl, String grant,
          {required String deviceUid, required String commandUid, required bool active}) =>
      _command(baseUrl, '/edge/api/v1/maintenance', grant,
          {'deviceId': deviceUid, 'commandUid': commandUid, 'active': active});

  /// Mutes or restores the buzzer of the device (US-49).
  Future<GatewayDirectivesResource> setBuzzerMuted(String baseUrl, String grant,
          {required String deviceUid, required String commandUid, required bool muted}) =>
      _command(baseUrl, '/edge/api/v1/buzzer/mute', grant,
          {'deviceId': deviceUid, 'commandUid': commandUid, 'muted': muted});

  /// Asks the device to run one signal test of its LEDs and buzzer (US-49).
  Future<GatewayDirectivesResource> requestSignalTest(String baseUrl, String grant,
          {required String deviceUid, required String commandUid}) =>
      _command(baseUrl, '/edge/api/v1/signal-tests', grant, {'deviceId': deviceUid, 'commandUid': commandUid});

  Future<GatewayDirectivesResource> _command(
      String baseUrl, String path, String grant, Map<String, Object> body) async {
    final http.Response response;
    try {
      response = await _http
          .post(
            _uri(baseUrl, path),
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'X-Edge-Grant': grant},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } on Exception {
      throw const EdgeGatewayException(GatewayErrorKind.unreachable);
    }
    final text = utf8.decode(response.bodyBytes);
    if (response.statusCode == 200) {
      return GatewayDirectivesResource.fromJson(jsonDecode(text) as Map<String, dynamic>);
    }
    String? message;
    try {
      message = (jsonDecode(text) as Map<String, dynamic>)['error'] as String?;
    } on Exception {
      message = null;
    }
    throw EdgeGatewayException(
      switch (response.statusCode) {
        401 => GatewayErrorKind.unauthorized,
        409 => GatewayErrorKind.conflict,
        _ => GatewayErrorKind.rejected,
      },
      message,
    );
  }

  Uri _uri(String baseUrl, String path) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return Uri.parse('$base$path');
  }
}
