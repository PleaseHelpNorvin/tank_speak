import 'package:flutter/foundation.dart';

/// Build-time configuration for the TankSpeak mobile client.
///
/// Values come from `--dart-define`. Without `API_BASE_URL` the app uses the
/// live TankSpeak server. Examples:
///
/// ```text
/// flutter run                                   (live server)
/// flutter run --dart-define=API_BASE_URL=local    (local uvicorn)
/// flutter build apk --dart-define=API_BASE_URL=https://api.example.com --dart-define=APP_ENV=production
/// ```
///
/// `API_BASE_URL` may be given with or without the trailing `/api`.
class AppConfig {
  AppConfig._();

  static const String _baseUrlDefine =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// `development`, `testing` or `production`. Only used for display and to
  /// decide whether a local fallback URL is acceptable.
  static const String environment =
      String.fromEnvironment('APP_ENV', defaultValue: 'development');

  /// Must match the backend's `DEVICE_ONLINE_MINUTES` (default 15).
  static const int deviceOnlineMinutes =
      int.fromEnvironment('DEVICE_ONLINE_MINUTES', defaultValue: 15);

  /// Must match the backend's `DEVICE_STALE_MINUTES` (default 60).
  static const int deviceStaleMinutes =
      int.fromEnvironment('DEVICE_STALE_MINUTES', defaultValue: 60);

  /// How often open telemetry screens refresh themselves.
  static const int telemetryRefreshSeconds =
      int.fromEnvironment('TELEMETRY_REFRESH_SECONDS', defaultValue: 30);

  static const Duration requestTimeout = Duration(seconds: 20);

  static bool get isProduction => environment == 'production';

  /// The live TankSpeak server, used when no API_BASE_URL is given.
  static const String liveServerOrigin = 'https://129.121.115.28';

  /// Base URL of the backend API, always ending in `/api` without a slash.
  ///
  /// * not set                      -> the live server ([liveServerOrigin])
  /// * `API_BASE_URL=local`         -> local uvicorn (emulator: 10.0.2.2)
  /// * `API_BASE_URL=https://host`  -> that server
  static String get apiBaseUrl {
    final configured = _baseUrlDefine.trim();
    if (configured.isEmpty) return normalizeApiBase(liveServerOrigin);
    if (configured.toLowerCase() == 'local') {
      return normalizeApiBase(localDevelopmentOrigin());
    }
    return normalizeApiBase(configured);
  }

  /// Local FastAPI dev server (`uvicorn main:app --port 8000`).
  ///
  /// The Android emulator reaches the host machine through 10.0.2.2; every
  /// other target (web, desktop, iOS simulator) uses 127.0.0.1. A physical
  /// phone needs API_BASE_URL set to the computer's LAN address.
  static String localDevelopmentOrigin() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  /// Accepts `https://host`, `https://host/`, `https://host/api` or
  /// `https://host/api/` and returns `https://host/api`.
  static String normalizeApiBase(String value) {
    var url = value.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (!url.endsWith('/api')) url = '$url/api';
    return url;
  }
}
