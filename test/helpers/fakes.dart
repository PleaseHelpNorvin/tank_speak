import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tank_speak/core/token_storage.dart';
import 'package:tank_speak/services/api_service.dart';
import 'package:tank_speak/services/auth_service.dart';

/// In-memory replacement for secure storage.
class MemoryTokenStorage extends TokenStorage {
  MemoryTokenStorage([this.token]);

  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async => token = value;

  @override
  Future<void> clear() async => token = null;
}

/// Loads a response captured from the real backend (test/fixtures).
/// Returns `{"status": int, "body": ...}`.
Map<String, dynamic> fixture(String name) {
  final file = File('test/fixtures/$name');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

dynamic fixtureBody(String name) => fixture(name)['body'];

http.Response jsonResponse(Object? body, [int status = 200]) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json'});

http.Response fixtureResponse(String name) {
  final f = fixture(name);
  return jsonResponse(f['body'], f['status'] as int);
}

/// Every request the client sent.
final List<http.Request> sentRequests = [];

/// Installs a fake HTTP backend and fresh singletons.
MemoryTokenStorage installFakeBackend(
  Future<http.Response> Function(http.Request request) handler, {
  String? token,
}) {
  sentRequests.clear();
  final tokens = MemoryTokenStorage(token);
  ApiService.overrideForTesting(
    client: MockClient((request) {
      sentRequests.add(request);
      return handler(request);
    }),
    tokens: tokens,
  );
  AuthService.resetForTesting();
  return tokens;
}
