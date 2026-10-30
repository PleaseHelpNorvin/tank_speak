import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:tank_speak/core/api_exception.dart';
import 'package:tank_speak/services/api_service.dart';
import 'package:tank_speak/services/device_service.dart';
import 'package:tank_speak/services/station_service.dart';

import 'helpers/fakes.dart';

void main() {
  test('adds the bearer token and JSON headers', () async {
    installFakeBackend((_) async => fixtureResponse('me_member.json'),
        token: 'abc');
    await ApiService.instance.get('/me');
    final r = sentRequests.single;
    expect(r.headers['Authorization'], 'Bearer abc');
    expect(r.headers['Accept'], 'application/json');
    expect(r.url.toString(), 'http://test.local/api/me');
  });

  test('unauthenticated calls send no Authorization header', () async {
    installFakeBackend((_) async => fixtureResponse('login_failure.json'),
        token: 'abc');
    await ApiService.instance
        .post('/login', auth: false, body: {'username': 'u', 'password': 'p'});
    expect(sentRequests.single.headers.containsKey('Authorization'), isFalse);
    expect(sentRequests.single.headers['Content-Type'],
        startsWith('application/json'));
  });

  test('no stored token fails before any request', () async {
    installFakeBackend((_) async => jsonResponse({}));
    await expectLater(ApiService.instance.get('/me'),
        throwsA(isA<ApiException>().having((e) => e.isUnauthorized, '401', true)));
    expect(sentRequests, isEmpty);
  });

  test('401 clears the token and notifies listeners', () async {
    final tokens = installFakeBackend(
        (_) async => fixtureResponse('error_401.json'),
        token: 'expired');
    final events = <ApiException>[];
    final sub = ApiService.instance.unauthorizedEvents.listen(events.add);

    await expectLater(ApiService.instance.get('/me'),
        throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.unauthorized)));
    await Future<void>.delayed(Duration.zero);

    expect(tokens.token, isNull);
    expect(events, hasLength(1));
    await sub.cancel();
  });

  test('403 keeps the token (no logout)', () async {
    final tokens = installFakeBackend(
        (_) async => fixtureResponse('error_403_company.json'),
        token: 'valid');
    await expectLater(
      ApiService.instance.get('/company/c/21'),
      throwsA(isA<ApiException>()
          .having((e) => e.kind, 'kind', ApiErrorKind.forbidden)
          .having((e) => e.message, 'message',
              'You do not have access to this company')),
    );
    expect(tokens.token, 'valid');
  });

  test('422 lists the invalid fields', () async {
    installFakeBackend((_) async => fixtureResponse('error_422.json'),
        token: 't');
    try {
      await ApiService.instance.post('/company/create', body: {'name': 'x'});
      fail('should throw');
    } on ApiException catch (e) {
      expect(e.kind, ApiErrorKind.validation);
      expect(e.fieldErrors.keys, contains('address'));
      expect(e.message, contains('Address'));
    }
  });

  test('status codes map to readable errors', () async {
    final cases = {
      400: ApiErrorKind.badRequest,
      404: ApiErrorKind.notFound,
      409: ApiErrorKind.conflict,
      429: ApiErrorKind.rateLimited,
      500: ApiErrorKind.server,
      503: ApiErrorKind.server,
    };
    for (final entry in cases.entries) {
      installFakeBackend(
          (_) async => jsonResponse({'detail': 'x'}, entry.key),
          token: 't');
      await expectLater(ApiService.instance.get('/x'),
          throwsA(isA<ApiException>().having((e) => e.kind, '${entry.key}', entry.value)));
    }
  });

  test('server errors never expose the body', () async {
    installFakeBackend(
        (_) async => http.Response('Traceback (most recent call last): ...', 500),
        token: 't');
    try {
      await ApiService.instance.get('/x');
      fail('should throw');
    } on ApiException catch (e) {
      expect(e.message, isNot(contains('Traceback')));
    }
  });

  test('invalid JSON on success is reported', () async {
    installFakeBackend((_) async => http.Response('<html>', 200), token: 't');
    await expectLater(ApiService.instance.get('/x'),
        throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.invalidResponse)));
  });

  test('network failures are reported as network errors', () async {
    installFakeBackend((_) async => throw http.ClientException('refused'),
        token: 't');
    await expectLater(ApiService.instance.get('/x'),
        throwsA(isA<ApiException>().having((e) => e.isNetwork, 'network', true)));
  });

  test('timeouts are reported', () async {
    installFakeBackend((_) async => throw TimeoutException('slow'), token: 't');
    await expectLater(ApiService.instance.get('/x'),
        throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.timeout)));
  });

  test('readings request uses device_key query and encoded channel', () async {
    installFakeBackend((_) async => fixtureResponse('readings.json'), token: 't');
    final r = await DeviceService().getReadings(
      deviceId: 4,
      deviceKey: '90:70:69:82:0B:6C',
      channelKey: 'A0',
      range: 'week',
      limit: 100,
    );
    final url = sentRequests.single.url;
    expect(url.path, '/api/device/4/A0/readings');
    expect(url.queryParameters['device_key'], '90:70:69:82:0B:6C');
    expect(url.queryParameters['range'], 'week');
    expect(r.readings, isNotEmpty);
  });

  test('channel mapping goes to /device-channel and keeps the unit', () async {
    installFakeBackend((_) async => jsonResponse({'message': 'ok'}), token: 't');
    await DeviceService().saveChannelMapping(
        deviceId: 4, channelKey: 'A1', label: ' Diesel ', unit: 'cm');
    final r = sentRequests.single;
    expect(r.url.path, '/api/device-channel/4/channel-mapping');
    expect(r.body, '{"key":"A1","label":"Diesel","unit":"cm"}');
  });

  test('device registration strips BLE control characters', () async {
    installFakeBackend(
        (_) async => jsonResponse({
              'message': 'successfully registered the device',
              'device': {'id': 9, 'device_key': 'AA:BB'},
              'station': {'id': 1}
            }),
        token: 't');
    final result = await DeviceService()
        .registerDevice(deviceKey: 'AA:BB\u0000\n', stationId: 1);
    expect(sentRequests.single.body, '{"key":"AA:BB","station_id":1}');
    expect(result.device.id, 9);
  });

  test('station detail falls back when device metadata is forbidden', () async {
    installFakeBackend((request) async {
      if (request.url.path == '/api/station/g/13') {
        return fixtureResponse('station_detail.json');
      }
      return jsonResponse({'detail': 'Station not found'}, 404);
    }, token: 't');
    final detail = await StationService().getStationWithDeviceStatus(13);
    expect(detail.devices.single.device.lastSeen, isNull);
    expect(detail.devices.single.channels, isNotEmpty);
  });

  test('station detail merges last_seen when available', () async {
    installFakeBackend((request) async {
      if (request.url.path == '/api/station/g/13') {
        return fixtureResponse('station_detail.json');
      }
      return fixtureResponse('station_devices.json');
    }, token: 't');
    final detail = await StationService().getStationWithDeviceStatus(13);
    expect(sentRequests.last.url.path, '/api/station/8/13/devices');
    expect(detail.devices.single.device.lastSeen, isNotNull);
  });
}
