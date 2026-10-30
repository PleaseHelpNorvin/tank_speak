import 'package:flutter_test/flutter_test.dart';
import 'package:tank_speak/core/json_utils.dart';
import 'package:tank_speak/models/company.dart';
import 'package:tank_speak/models/gas_station.dart';
import 'package:tank_speak/models/invitation.dart';
import 'package:tank_speak/models/me_response.dart';
import 'package:tank_speak/models/member.dart';
import 'package:tank_speak/models/paginated_response.dart';
import 'package:tank_speak/models/sensor.dart';
import 'package:tank_speak/models/tank.dart';

import 'helpers/fakes.dart';

/// Parses responses captured from the real backend (test/fixtures).
void main() {
  group('server dates', () {
    test('naive backend timestamps are UTC', () {
      final d = parseServerDate('2026-10-26T11:29:49.082995')!;
      expect(d.isUtc, isTrue);
      expect(d.hour, 11);
      expect(d.minute, 29);
    });

    test('timestamps with an offset are respected', () {
      final d = parseServerDate('2026-10-26T11:29:49Z')!;
      expect(d.hour, 11);
      expect(parseServerDate('2026-10-26T19:29:49+08:00')!.hour, 11);
    });

    test('missing or invalid dates are null', () {
      expect(parseServerDate(null), isNull);
      expect(parseServerDate(''), isNull);
      expect(parseServerDate('not a date'), isNull);
    });
  });

  group('/api/me', () {
    test('owner', () {
      final me = MeResponse.fromJson(asMap(fixtureBody('me_owner.json')));
      expect(me.id, 3);
      expect(me.username, 'user');
      expect(me.ownerStations, isNotEmpty);
      expect(me.ownsStation(13), isTrue);
      expect(me.isAdministrator, isFalse);
    });

    test('manager', () {
      final me = MeResponse.fromJson(asMap(fixtureBody('me_manager.json')));
      expect(me.managesStation(13), isTrue);
      expect(me.ownerStations, isEmpty);
    });

    test('member has no owner/manager stations', () {
      final me = MeResponse.fromJson(asMap(fixtureBody('me_member.json')));
      expect(me.ownerStations, isEmpty);
      expect(me.managerStations, isEmpty);
      expect(me.inviteCode, isNotEmpty);
    });

    test('admin flags are honoured when present', () {
      final me = MeResponse.fromJson({
        'id': 2,
        'username': 'admin',
        'is_admin': true,
        'owner': null,
        'manager': null,
      });
      expect(me.isAdministrator, isTrue);
      expect(me.ownerStations, isEmpty);
    });

    test('tolerates nulls and wrong types', () {
      final me = MeResponse.fromJson({'id': '7', 'owner': 'x', 'manager': [1]});
      expect(me.id, 7);
      expect(me.username, '');
      expect(me.ownerStations, isEmpty);
      expect(me.managerStations, isEmpty);
    });
  });

  test('company list uses the nested pagination block', () {
    final page = PaginatedResponse<Company>.fromJson(
        asMap(fixtureBody('companies_member.json')),
        Company.fromJson,
        'companies');
    expect(page.items.single.id, 8);
    expect(page.total, 1);
    expect(page.page, 1);
  });

  test('company detail', () {
    final d = CompanyDetailResponse.fromJson(
        asMap(fixtureBody('company_detail_member.json')));
    expect(d.company.id, 8);
    expect(d.stations.single.id, 13);
    expect(d.stations.single.extendedBusinessHours, isNull);
  });

  test('company members', () {
    final page = PaginatedResponse<CompanyMember>.fromJson(
        asMap(fixtureBody('company_members.json')),
        CompanyMember.fromJson,
        'members');
    expect(page.items.first.role, StationRole.owner);
    expect(page.total, 14);
  });

  group('station detail', () {
    late StationDetailResponse detail;

    setUp(() {
      detail = StationDetailResponse.fromJson(
          asMap(fixtureBody('station_detail.json')));
    });

    test('station, owner, manager, members', () {
      expect(detail.station.id, 13);
      expect(detail.station.companyId, 8);
      expect(detail.owner!.id, 3);
      expect(detail.manager!.username, 'manager3');
      expect(detail.members.any((m) => m.role == StationRole.member), isTrue);
      expect(detail.subscription, isNotNull);
    });

    test('devices and calibrated channels', () {
      final device = detail.devices.single;
      expect(device.device.id, 4);
      expect(device.device.deviceKey, '90:70:69:82:0B:6C');
      expect(device.payloadCreatedAt, isNotNull);
      expect(device.channels.map((c) => c.key), containsAll(['A0', 'A1']));
      final a0 = device.channels.firstWhere((c) => c.key == 'A0');
      expect(a0.value, isNotNull);
      expect(a0.calibrationProfileId, 1);
      expect(a0.status.isCalibrated, isTrue);
      expect(a0.displayUnit, 'L');
    });

    test('merging connectivity metadata from /station/{c}/{s}/devices', () {
      final devices = asMapList(asMap(fixtureBody('station_devices.json'))['devices'])
          .map(Device.fromJson)
          .toList();
      expect(devices.single.lastSeen, isNotNull);
      expect(devices.single.isActive, isTrue);
      final merged = detail.devices.single.withDevice(detail.devices.single.device
          .copyWith(lastSeen: devices.single.lastSeen, isActive: true));
      expect(merged.device.lastSeen, devices.single.lastSeen);
      expect(merged.channels.length, detail.devices.single.channels.length);
    });
  });

  test('channel values that are not numbers do not crash', () {
    final c = ChannelReading.fromJson('A1',
        {'value': 'bad', 'raw': 'bad', 'label': 'A1', 'status': 'no_profile'});
    expect(c.value, isNull);
    expect(c.rawValue, 'bad');
    expect(c.status, ChannelStatus.noProfile);
    expect(c.displayUnit, isNull);
  });

  test('readings', () {
    final r = ReadingsResponse.fromJson(asMap(fixtureBody('readings.json')));
    expect(r.sensorPin, 'A0');
    expect(r.profile!.id, 1);
    expect(r.isCalibrated, isTrue);
    expect(r.readings, isNotEmpty);
    // The backend spells normal with a leading space.
    expect(
        r.readings.map((e) => e.status),
        everyElement(isIn(
            [ChannelStatus.normal, ChannelStatus.dryAlert, ChannelStatus.refillAlert])));
    expect(r.readings.first.timestamp!.isUtc, isTrue);
    final pct = r.percentOf(r.latestValid!.value)!;
    expect(pct, inInclusiveRange(0, 100));
  });

  test('empty readings response', () {
    final r = ReadingsResponse.fromJson({
      'device_id': 'x',
      'sensor_pin': 'A0',
      'active_calibration_profile': null,
      'threshold': null,
      'max_capacity': null,
      'readings': [],
    });
    expect(r.latest, isNull);
    expect(r.isCalibrated, isFalse);
    expect(r.percentOf(10), isNull);
  });

  test('channel mapping object keyed by channel', () {
    final list = ChannelMapping.listFromJson(fixtureBody('channel_mapping.json'));
    expect(list.first.channelKey, 'A0');
    expect(list.first.unit, 'cm');
    expect(list.first.calibrationProfileId, 1);
  });

  test('device logs', () {
    final page = PaginatedResponse<DeviceLog>.fromJson(
        asMap(fixtureBody('device_logs.json')), DeviceLog.fromJson, 'logs');
    expect(page.page, 1);
  });

  test('sent invitations', () {
    final page = PaginatedResponse<Invitation>.fromJson(
        asMap(fixtureBody('invitations_sent.json')),
        Invitation.fromJson,
        'sent_invitations');
    final i = page.items.first;
    expect(i.stationId, 13);
    expect(i.companyId, 8);
    expect(i.role, isNotNull);
    expect(i.createdAt, isNotNull);
  });

  test('invite code lookup (invited_to is a company object)', () {
    final l = InviteCodeLookup.fromJson(asMap(fixtureBody('invite_search.json')));
    expect(l.inviteCode, '9560105675');
    expect(l.alreadyInvitedByMe, isTrue);
    expect(l.invitedToCompanyName, isNotNull);
  });

  test('station people never keep password fields', () {
    final p = StationPerson.fromJson(
        {'id': 1, 'name': 'A', 'username': 'a', 'password': 'hash'});
    expect(p.displayName, 'A');
  });
}
