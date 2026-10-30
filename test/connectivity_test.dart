import 'package:flutter_test/flutter_test.dart';
import 'package:tank_speak/config/app_config.dart';
import 'package:tank_speak/models/connectivity.dart';

void main() {
  final now = DateTime.utc(2026, 10, 30, 12, 0);
  DeviceConnectivity eval({bool? active, Duration? seen, Duration? payload}) =>
      DeviceConnectivity.evaluate(
        isActive: active,
        lastSeen: seen == null ? null : now.subtract(seen),
        lastPayloadAt: payload == null ? null : now.subtract(payload),
        now: now,
        onlineMinutes: 15,
        staleMinutes: 60,
      );

  test('online with recent telemetry', () {
    final c = eval(active: true, seen: const Duration(minutes: 2),
        payload: const Duration(minutes: 2));
    expect(c.state, ConnectivityState.online);
    expect(c.freshness, ReadingsFreshness.fresh);
    expect(c.readingsAreLive, isTrue);
  });

  test('offline', () {
    final c = eval(active: true, seen: const Duration(hours: 3),
        payload: const Duration(hours: 3));
    expect(c.state, ConnectivityState.offline);
    expect(c.freshness, ReadingsFreshness.stale);
    expect(c.readingsAreLive, isFalse);
  });

  test('online but telemetry outdated', () {
    final c = eval(active: true, seen: const Duration(minutes: 1),
        payload: const Duration(hours: 5));
    expect(c.state, ConnectivityState.online);
    expect(c.freshness, ReadingsFreshness.stale);
    expect(c.readingsAreLive, isFalse);
    expect(c.summary, contains('outdated'));
  });

  test('never submitted telemetry', () {
    final c = eval(active: true);
    expect(c.state, ConnectivityState.never);
    expect(c.freshness, ReadingsFreshness.none);
  });

  test('online without readings yet', () {
    final c = eval(active: true, seen: const Duration(minutes: 1));
    expect(c.state, ConnectivityState.online);
    expect(c.freshness, ReadingsFreshness.none);
  });

  test('delayed between the two thresholds', () {
    expect(eval(seen: const Duration(minutes: 30)).state,
        ConnectivityState.delayed);
  });

  test('disabled wins', () {
    expect(eval(active: false, seen: const Duration(minutes: 1)).state,
        ConnectivityState.disabled);
  });

  test('payload time is used when last_seen is unknown', () {
    final c = eval(payload: const Duration(minutes: 3));
    expect(c.state, ConnectivityState.online);
    expect(c.lastContact, now.subtract(const Duration(minutes: 3)));
  });

  group('AppConfig', () {
    test('normalises the API base URL', () {
      expect(AppConfig.normalizeApiBase('https://x.com'), 'https://x.com/api');
      expect(AppConfig.normalizeApiBase('https://x.com/'), 'https://x.com/api');
      expect(AppConfig.normalizeApiBase('https://x.com/api'), 'https://x.com/api');
      expect(AppConfig.normalizeApiBase(' http://10.0.2.2:8000/api/ '),
          'http://10.0.2.2:8000/api');
    });

    test('defaults match the backend thresholds', () {
      expect(AppConfig.deviceOnlineMinutes, 15);
      expect(AppConfig.deviceStaleMinutes, 60);
      // No API_BASE_URL in tests -> the live server.
      expect(AppConfig.apiBaseUrl, 'https://129.121.115.28/api');
    });
  });
}
