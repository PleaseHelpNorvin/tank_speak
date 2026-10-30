import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../core/api_exception.dart';
import '../core/token_storage.dart';

/// The single place where the app talks HTTP to the TankSpeak backend.
///
/// * base URL from [AppConfig] (`--dart-define=API_BASE_URL=...`)
/// * `Authorization: Bearer <UserToken>` on authenticated calls
/// * JSON encoding/decoding, timeouts and error mapping to [ApiException]
/// * a 401 on an authenticated call clears the stored token and notifies
///   [unauthorizedEvents] so the app can return to the sign-in screen.
///   A 403 never signs the user out.
///
/// Bearer tokens and request bodies are never logged.
class ApiService {
  ApiService._({http.Client? client, TokenStorage? tokens, String? baseUrl})
      : _client = client ?? http.Client(),
        tokens = tokens ?? TokenStorage(),
        _baseUrl = baseUrl;

  static ApiService _instance = ApiService._();

  /// Shared instance used by every feature service.
  static ApiService get instance => _instance;

  /// Replaces the shared instance (tests only).
  @visibleForTesting
  static void overrideForTesting({
    required http.Client client,
    required TokenStorage tokens,
    String baseUrl = 'http://test.local/api',
  }) {
    _instance = ApiService._(client: client, tokens: tokens, baseUrl: baseUrl);
  }

  final http.Client _client;
  final TokenStorage tokens;
  final String? _baseUrl;

  final StreamController<ApiException> _unauthorized =
      StreamController<ApiException>.broadcast();

  /// Emits when the backend rejected the stored token (401).
  Stream<ApiException> get unauthorizedEvents => _unauthorized.stream;

  String get baseUrl => _baseUrl ?? AppConfig.apiBaseUrl;

  /// Encodes one path segment (device keys contain `:`).
  static String seg(Object value) => Uri.encodeComponent(value.toString());

  Uri buildUri(String path, [Map<String, Object?>? query]) {
    final params = <String, String>{};
    query?.forEach((key, value) {
      if (value == null) return;
      final text = value.toString();
      if (text.isEmpty) return;
      params[key] = text;
    });

    final uri = Uri.parse('$baseUrl$path');
    return params.isEmpty ? uri : uri.replace(queryParameters: params);
  }

  Future<dynamic> get(String path,
          {Map<String, Object?>? query, bool auth = true}) =>
      _send('GET', path, query: query, auth: auth);

  Future<dynamic> post(String path,
          {Object? body, Map<String, Object?>? query, bool auth = true}) =>
      _send('POST', path, body: body, query: query, auth: auth);

  Future<dynamic> put(String path,
          {Object? body, Map<String, Object?>? query, bool auth = true}) =>
      _send('PUT', path, body: body, query: query, auth: auth);

  Future<dynamic> delete(String path,
          {Map<String, Object?>? query, bool auth = true}) =>
      _send('DELETE', path, query: query, auth: auth);

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, Object?>? query,
    required bool auth,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';

    String? token;
    if (auth) {
      token = await tokens.read();
      if (token == null) {
        throw ApiException(
          kind: ApiErrorKind.unauthorized,
          statusCode: 401,
          message: 'Please sign in to continue.',
        );
      }
      headers['Authorization'] = 'Bearer $token';
    }

    final uri = buildUri(path, query);
    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    http.Response response;
    try {
      final streamed =
          await _client.send(request).timeout(AppConfig.requestTimeout);
      response = await http.Response.fromStream(streamed)
          .timeout(AppConfig.requestTimeout);
    } on TimeoutException {
      throw ApiException(
        kind: ApiErrorKind.timeout,
        message: 'The server took too long to respond. '
            'Check your connection and try again.',
      );
    } on http.ClientException {
      throw _networkError();
    } catch (_) {
      // SocketException / HandshakeException (dart:io) are not importable on
      // web, so anything else thrown by the transport is a network failure.
      throw _networkError();
    }

    if (kDebugMode) {
      debugPrint('[api] $method ${uri.path} -> ${response.statusCode}');
    }

    final decoded = _decode(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is _InvalidJson) {
        throw ApiException(
          kind: ApiErrorKind.invalidResponse,
          statusCode: response.statusCode,
          message: 'The server sent a response the app could not read.',
        );
      }
      return decoded;
    }

    final error = ApiException.fromResponse(
      response.statusCode,
      decoded is _InvalidJson ? null : decoded,
    );

    if (error.isUnauthorized && auth) {
      // Only drop the token if it is still the one this request used; a
      // newer login must not be undone by a late response.
      if (await tokens.read() == token) {
        await tokens.clear();
        _unauthorized.add(error);
      }
    }

    throw error;
  }

  ApiException _networkError() => ApiException(
        kind: ApiErrorKind.network,
        message: 'Cannot reach the TankSpeak server. '
            'Check your internet connection and try again.',
      );

  Object? _decode(http.Response response) {
    final text = utf8.decode(response.bodyBytes, allowMalformed: true).trim();
    if (text.isEmpty) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      return const _InvalidJson();
    }
  }
}

class _InvalidJson {
  const _InvalidJson();
}
