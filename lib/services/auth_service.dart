import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../core/json_utils.dart';
import '../models/me_response.dart';
import 'api_service.dart';

/// Result of restoring a session at start-up.
enum SessionRestore { signedIn, signedOut, adminBlocked }

/// Authentication against the backend's `UserToken` bearer tokens
/// (`POST /api/login`, `GET /api/me`, `POST /api/logout`).
///
/// Tokens expire after 30 days on the server and there is no refresh
/// endpoint, so an expired token simply sends the user back to sign-in.
/// Browser cookie sessions (`UserSession`) are not used by the app.
class AuthService extends ChangeNotifier {
  AuthService._(this._api) {
    _unauthorizedSub = _api.unauthorizedEvents.listen(_onUnauthorized);
  }

  static AuthService? _instance;

  static AuthService get instance =>
      _instance ??= AuthService._(ApiService.instance);

  @visibleForTesting
  static void resetForTesting() {
    _instance?._unauthorizedSub?.cancel();
    _instance = null;
  }

  final ApiService _api;
  StreamSubscription<ApiException>? _unauthorizedSub;

  MeResponse? _me;
  String? _sessionEndedMessage;

  /// The signed-in user, or null.
  MeResponse? get me => _me;

  bool get isSignedIn => _me != null;

  /// Set when the server invalidated the session; shown on the sign-in
  /// screen and then cleared.
  String? takeSessionEndedMessage() {
    final message = _sessionEndedMessage;
    _sessionEndedMessage = null;
    return message;
  }

  static const String adminBlockedMessage =
      'Administrator accounts cannot use the TankSpeak mobile app. '
      'Please use the TankSpeak web administration portal.';

  /// Signs in and loads the profile. Throws [ApiException] on failure.
  Future<MeResponse> login(String username, String password) async {
    final body = asMap(await _api.post(
      '/login',
      auth: false,
      body: {'username': username.trim(), 'password': password},
    ));

    // The backend answers 200 with {"success": false, "msg": ...} for bad
    // credentials (and for deleted accounts).
    final token = asText(body['token']);
    if (body['success'] != true || token == null) {
      throw ApiException(
        kind: ApiErrorKind.unauthorized,
        statusCode: 200,
        message: 'Incorrect username or password.',
      );
    }

    await _api.tokens.write(token);

    final MeResponse profile;
    try {
      profile = await fetchMe();
    } catch (_) {
      await _api.tokens.clear();
      rethrow;
    }

    if (profile.isAdministrator) {
      await _revokeAndClear();
      throw ApiException(
        kind: ApiErrorKind.forbidden,
        statusCode: 403,
        message: adminBlockedMessage,
      );
    }

    _me = profile;
    notifyListeners();
    return profile;
  }

  /// Restores a stored session after an app restart.
  ///
  /// A network error keeps the token (the user is offline, not signed out)
  /// and is rethrown so the caller can offer a retry.
  Future<SessionRestore> restore() async {
    final token = await _api.tokens.read();
    if (token == null) {
      _me = null;
      return SessionRestore.signedOut;
    }

    try {
      final profile = await fetchMe();
      if (profile.isAdministrator) {
        await _revokeAndClear();
        _sessionEndedMessage = adminBlockedMessage;
        return SessionRestore.adminBlocked;
      }
      _me = profile;
      notifyListeners();
      return SessionRestore.signedIn;
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        _me = null;
        return SessionRestore.signedOut;
      }
      rethrow;
    }
  }

  /// `GET /api/me`. Updates the cached profile.
  Future<MeResponse> fetchMe() async {
    final profile = MeResponse.fromJson(asMap(await _api.get('/me')));
    if (_me != null) {
      _me = profile;
      notifyListeners();
    }
    return profile;
  }

  /// Reloads the profile (e.g. after accepting an invitation).
  Future<void> refreshProfile() async {
    final profile = await fetchMe();
    _me = profile;
    notifyListeners();
  }

  Future<void> register({
    required String username,
    required String name,
    required String email,
    required String password,
  }) async {
    await _api.post('/register', auth: false, body: {
      'username': username.trim(),
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
    });
  }

  /// Revokes the token on the server (best effort) and clears it locally.
  Future<void> logout() async {
    await _revokeAndClear();
    _me = null;
    notifyListeners();
  }

  Future<void> _revokeAndClear() async {
    final token = await _api.tokens.read();
    if (token != null) {
      try {
        // The backend's logout takes the token as the `current_token`
        // query parameter and needs no Authorization header.
        await _api.post('/logout', auth: false, query: {'current_token': token});
      } catch (_) {
        // Offline or already invalid: clearing locally is what matters.
      }
    }
    await _api.tokens.clear();
  }

  void _onUnauthorized(ApiException error) {
    if (_me == null) return;
    _me = null;
    _sessionEndedMessage = error.message;
    notifyListeners();
  }
}
