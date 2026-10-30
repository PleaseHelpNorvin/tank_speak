import '../core/json_utils.dart';
import 'calibration_profile.dart';

/// A registered Norvi device (`devices` row).
///
/// The station detail endpoint only sends id/name/device_key/type; the
/// station devices endpoint also sends `is_active` and `last_seen`.
class Device {
  Device({
    required this.id,
    required this.name,
    required this.deviceKey,
    required this.type,
    this.stationId,
    this.isActive,
    this.lastSeen,
    this.createdAt,
  });

  final int id;
  final String name;

  /// The MAC address the hardware reports; telemetry is keyed by it.
  final String deviceKey;
  final String type;
  final int? stationId;
  final bool? isActive;
  final DateTime? lastSeen;
  final DateTime? createdAt;

  String get displayName => name.isNotEmpty ? name : deviceKey;

  Device copyWith({bool? isActive, DateTime? lastSeen, int? stationId}) {
    return Device(
      id: id,
      name: name,
      deviceKey: deviceKey,
      type: type,
      stationId: stationId ?? this.stationId,
      isActive: isActive ?? this.isActive,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt,
    );
  }

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: asInt(json['id']) ?? 0,
      name: asString(json['name']) ?? '',
      deviceKey: asString(json['device_key']) ?? '',
      type: asString(json['type']) ?? '',
      stationId: asInt(json['station_id']),
      isActive: asBool(json['is_active']),
      lastSeen: parseServerDate(json['last_seen']),
      createdAt: parseServerDate(json['created_at']),
    );
  }
}

/// Backend channel status values (`TelemetryService.process_channel` and the
/// readings endpoint). The readings endpoint spells normal as `" normal"`.
enum ChannelStatus {
  normal,
  dryAlert,
  refillAlert,
  noProfile,
  noData,
  invalid,
  unknown,
}

ChannelStatus parseChannelStatus(Object? value) {
  switch (asString(value)?.trim().toLowerCase()) {
    case 'normal':
      return ChannelStatus.normal;
    case 'dry_alert':
      return ChannelStatus.dryAlert;
    case 'refill_alert':
      return ChannelStatus.refillAlert;
    case 'no_profile':
      return ChannelStatus.noProfile;
    case 'no_data':
      return ChannelStatus.noData;
    case 'invalid':
      return ChannelStatus.invalid;
  }
  return ChannelStatus.unknown;
}

extension ChannelStatusLabel on ChannelStatus {
  String get label {
    switch (this) {
      case ChannelStatus.normal:
        return 'Normal';
      case ChannelStatus.dryAlert:
        return 'Low level';
      case ChannelStatus.refillAlert:
        return 'Refill detected';
      case ChannelStatus.noProfile:
        return 'Not calibrated';
      case ChannelStatus.noData:
        return 'No data';
      case ChannelStatus.invalid:
        return 'Invalid reading';
      case ChannelStatus.unknown:
        return 'Unknown';
    }
  }

  /// True when [ChannelReading.value] is a calibrated volume in liters.
  bool get isCalibrated =>
      this == ChannelStatus.normal ||
      this == ChannelStatus.dryAlert ||
      this == ChannelStatus.refillAlert;
}

/// One channel of the latest payload, as calibrated by the backend
/// (`latest_payload` entries of `/api/station/g/{id}`).
class ChannelReading {
  ChannelReading({
    required this.key,
    required this.label,
    required this.status,
    this.value,
    this.rawValue,
    this.unit,
    this.calibrationProfileId,
    this.refillAlert = false,
  });

  /// Channel key in the device payload, e.g. `A0`.
  final String key;
  final String label;
  final ChannelStatus status;

  /// Calibrated liters when [ChannelStatus.isCalibrated], otherwise the raw
  /// numeric value (or null if not numeric).
  final double? value;

  /// The raw value exactly as the device sent it.
  final Object? rawValue;
  final String? unit;
  final int? calibrationProfileId;
  final bool refillAlert;

  /// Unit to display next to [value].
  String? get displayUnit => status.isCalibrated ? 'L' : unit;

  factory ChannelReading.fromJson(String key, Object? data) {
    final json = asMap(data);
    if (json.isEmpty) {
      // Defensive: an older backend sent the bare raw value.
      return ChannelReading(
        key: key,
        label: key,
        status: data == null ? ChannelStatus.noData : ChannelStatus.noProfile,
        value: asDouble(data),
        rawValue: data,
      );
    }
    return ChannelReading(
      key: key,
      label: asText(json['label']) ?? key,
      status: parseChannelStatus(json['status']),
      value: asDouble(json['value']),
      rawValue: json['raw'],
      unit: asText(json['unit']),
      calibrationProfileId: asInt(json['active_calibration_profile_id']),
      refillAlert: asBool(json['refill_alert']) ?? false,
    );
  }
}

/// `devices[]` entry of `/api/station/g/{id}`.
class StationDevice {
  StationDevice({
    required this.device,
    required this.channels,
    this.payloadCreatedAt,
  });

  final Device device;
  final List<ChannelReading> channels;

  /// When the latest telemetry payload was stored (UTC), null if never.
  final DateTime? payloadCreatedAt;

  bool get hasTelemetry => payloadCreatedAt != null || channels.isNotEmpty;

  StationDevice withDevice(Device updated) => StationDevice(
        device: updated,
        channels: channels,
        payloadCreatedAt: payloadCreatedAt,
      );

  factory StationDevice.fromJson(Map<String, dynamic> json) {
    final latest = json['latest_payload'];
    final channels = <ChannelReading>[];
    if (latest is Map) {
      asMap(latest).forEach((key, value) {
        channels.add(ChannelReading.fromJson(key, value));
      });
      channels.sort((a, b) => a.key.compareTo(b.key));
    }
    return StationDevice(
      device: Device.fromJson(asMap(json['device'])),
      channels: channels,
      payloadCreatedAt: parseServerDate(json['payload_created_at']),
    );
  }
}

/// One point of `GET /api/device/{id}/{sensor_pin}/readings`.
class DeviceReading {
  DeviceReading({
    required this.status,
    this.timestamp,
    this.value,
    this.rawValue,
    this.event,
  });

  final DateTime? timestamp;

  /// Calibrated liters when the channel has a calibration profile, otherwise
  /// the raw numeric value. Null for `no_data` / `invalid`.
  final double? value;
  final Object? rawValue;
  final ChannelStatus status;

  /// `low`, `refill` or null.
  final String? event;

  bool get isRefill => event == 'refill' || status == ChannelStatus.refillAlert;
  bool get isLow => event == 'low' || status == ChannelStatus.dryAlert;

  factory DeviceReading.fromJson(Map<String, dynamic> json) {
    return DeviceReading(
      timestamp: parseServerDate(json['timestamp']),
      value: asDouble(json['value']),
      rawValue: json['raw'],
      status: parseChannelStatus(json['status']),
      event: asText(json['event']),
    );
  }
}

/// `GET /api/device/{id}/{sensor_pin}/readings` response.
class ReadingsResponse {
  ReadingsResponse({
    required this.deviceKey,
    required this.sensorPin,
    required this.readings,
    this.profile,
    this.threshold,
    this.maxCapacity,
  });

  final String deviceKey;
  final String sensorPin;
  final CalibrationProfile? profile;

  /// Low-level threshold in liters (null when there are no readings).
  final double? threshold;

  /// Largest volume in the calibration table (0/null if uncalibrated).
  final double? maxCapacity;

  /// Oldest first, as returned by the backend.
  final List<DeviceReading> readings;

  bool get isCalibrated => profile != null && (maxCapacity ?? 0) > 0;

  DeviceReading? get latest => readings.isEmpty ? null : readings.last;

  /// Latest reading that has a numeric value.
  DeviceReading? get latestValid {
    for (final r in readings.reversed) {
      if (r.value != null) return r;
    }
    return null;
  }

  /// Fill percentage from the backend-provided capacity (null if unknown).
  double? percentOf(double? liters) {
    final capacity = maxCapacity;
    if (liters == null || capacity == null || capacity <= 0) return null;
    return (liters / capacity * 100).clamp(0, 100).toDouble();
  }

  factory ReadingsResponse.fromJson(Map<String, dynamic> json) {
    final profile = json['active_calibration_profile'];
    return ReadingsResponse(
      deviceKey: asString(json['device_id']) ?? '',
      sensorPin: asString(json['sensor_pin']) ?? '',
      profile:
          profile is Map ? CalibrationProfile.fromJson(asMap(profile)) : null,
      threshold: asDouble(json['threshold']),
      maxCapacity: asDouble(json['max_capacity']),
      readings: asMapList(json['readings']).map(DeviceReading.fromJson).toList(),
    );
  }
}

/// `POST /api/device/register` response.
class RegisterDeviceResponse {
  RegisterDeviceResponse({required this.message, required this.device});

  final String message;
  final Device device;

  factory RegisterDeviceResponse.fromJson(Map<String, dynamic> json) {
    return RegisterDeviceResponse(
      message: asString(json['message']) ?? 'Device registered',
      device: Device.fromJson(asMap(json['device'])),
    );
  }
}
