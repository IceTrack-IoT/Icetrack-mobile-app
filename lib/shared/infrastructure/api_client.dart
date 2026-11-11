import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/state/app_state.dart';
import 'api_config.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Single HTTP client for the IceTrack backend.
///
/// - Adds `Authorization: Bearer`, JSON headers and `Accept-Language` (es / en).
/// - On a `401` it performs ONE shared refresh (single-flight) and replays the
///   failed request once; if the refresh fails the session is over and
///   [onSessionExpired] is called.
/// - Returns the decoded JSON (Map / List) or `null` for empty bodies (204).
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  final http.Client _http = http.Client();
  final TokenStorage _tokens = TokenStorage.instance;

  Future<bool>? _refreshInFlight;

  /// Set once in `main.dart`: sends the technician back to the sign-in screen.
  void Function()? onSessionExpired;

  Future<dynamic> get(String path, {Map<String, String>? query, bool authenticated = true}) =>
      _send('GET', path, query: query, authenticated: authenticated);

  Future<dynamic> post(String path, {Object? body, bool authenticated = true}) =>
      _send('POST', path, body: body, authenticated: authenticated);

  Future<dynamic> put(String path, {Object? body, Map<String, String>? query, bool authenticated = true}) =>
      _send('PUT', path, body: body, query: query, authenticated: authenticated);

  Future<dynamic> delete(String path, {Map<String, String>? query, bool authenticated = true}) =>
      _send('DELETE', path, query: query, authenticated: authenticated);

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    required bool authenticated,
    bool canRetry = true,
  }) async {
    final response = await _raw(method, ApiConfig.uri(path, query), body: body, authenticated: authenticated);

    if (response.statusCode == 401 && authenticated && canRetry) {
      final refreshed = await refreshSession();
      if (refreshed) {
        return _send(method, path, body: body, query: query, authenticated: authenticated, canRetry: false);
      }
      await _tokens.clear();
      onSessionExpired?.call();
    }

    final text = utf8.decode(response.bodyBytes);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return text.isEmpty ? null : jsonDecode(text);
    }
    throw ApiException.fromResponse(response.statusCode, text);
  }

  Future<http.Response> _raw(String method, Uri uri, {Object? body, required bool authenticated}) async {
    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Accept-Language'] = AppState.instance.languageCode;
    final token = _tokens.accessToken;
    if (authenticated && token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    try {
      final streamed = await _http.send(request).timeout(ApiConfig.timeout);
      return await http.Response.fromStream(streamed);
    } on ApiException {
      rethrow;
    } on Exception {
      // SocketException, ClientException, TimeoutException...
      throw const ApiException.network();
    }
  }

  /// Exchanges the stored refresh token for a new token pair.
  /// Concurrent callers share the same refresh. Returns false when the session
  /// cannot be renewed (expired, revoked, replayed or missing token).
  Future<bool> refreshSession() {
    return _refreshInFlight ??= _refresh().whenComplete(() => _refreshInFlight = null);
  }

  Future<bool> _refresh({bool isSecondAttempt = false}) async {
    final refreshToken = await _tokens.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    final response = await _raw(
      'POST',
      ApiConfig.uri('/authentication/refresh-token'),
      body: {'refresh_token': refreshToken, 'channel': ApiConfig.channel},
      authenticated: false,
    );
    final text = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200) {
      final json = jsonDecode(text) as Map<String, dynamic>;
      await _tokens.save(accessToken: json['token'] as String, refreshToken: json['refresh_token'] as String);
      return true;
    }

    final error = ApiException.fromResponse(response.statusCode, text);
    if (error.code == 'REFRESH_TOKEN_RECENTLY_ROTATED' && !isSecondAttempt) {
      // Another refresh won the race a moment ago: read the newest token and retry once.
      await Future<void>.delayed(const Duration(seconds: 1));
      return _refresh(isSecondAttempt: true);
    }
    return false;
  }
}
