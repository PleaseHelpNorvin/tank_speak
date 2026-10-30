import '../core/json_utils.dart';

/// `device_channel_mappings` row: label, unit and calibration profile of a
/// payload channel (`GET /api/device-channel/{device_id}/channel-mapping`).
class ChannelMapping {
  ChannelMapping({
    required this.id,
    required this.deviceId,
    required this.channelKey,
    this.label,
    this.unit,
    this.calibrationProfileId,
  });

  final int id;
  final int deviceId;
  final String channelKey;
  final String? label;
  final String? unit;
  final int? calibrationProfileId;

  String get displayLabel => label ?? channelKey;

  factory ChannelMapping.fromJson(String key, Map<String, dynamic> json) {
    return ChannelMapping(
      id: asInt(json['id']) ?? 0,
      deviceId: asInt(json['device_id']) ?? 0,
      channelKey: asText(json['channel_key']) ?? key,
      label: asText(json['label']),
      unit: asText(json['unit']),
      calibrationProfileId: asInt(json['calibration_profile_id']),
    );
  }

  /// The endpoint returns an object keyed by channel key.
  static List<ChannelMapping> listFromJson(Object? body) {
    final result = <ChannelMapping>[];
    asMap(body).forEach((key, value) {
      result.add(ChannelMapping.fromJson(key, asMap(value)));
    });
    result.sort((a, b) => a.channelKey.compareTo(b.channelKey));
    return result;
  }
}

/// `GET /api/device/{device_key}/logs` entries.
class DeviceLog {
  DeviceLog({
    required this.id,
    required this.level,
    required this.message,
    this.createdAt,
  });

  final int id;
  final String level;
  final String message;
  final DateTime? createdAt;

  factory DeviceLog.fromJson(Map<String, dynamic> json) {
    return DeviceLog(
      id: asInt(json['id']) ?? 0,
      level: asString(json['level']) ?? '',
      message: asString(json['message']) ?? '',
      createdAt: parseServerDate(json['created_at']),
    );
  }
}
