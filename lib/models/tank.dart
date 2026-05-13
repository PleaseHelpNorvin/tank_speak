class DeviceReading {
  final String deviceId;
  final String sensorPin;
  final double raw;
  final double height;
  final double liters;
  final DateTime timestamp;

  DeviceReading({
    required this.deviceId,
    required this.sensorPin,
    required this.raw,
    required this.height,
    required this.liters,
    required this.timestamp,
  });

  factory DeviceReading.fromJson(Map<String, dynamic> json) {
    return DeviceReading(
      deviceId: json['device_id'],
      sensorPin: json['sensor_pin'],
      raw: (json['raw'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      liters: (json['liters'] as num).toDouble(), // FIX HERE
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  static List<DeviceReading> listFromJson(dynamic json) {
    return (json as List)
        .map((e) => DeviceReading.fromJson(e))
        .toList();
  }
}

class Device {
  final String id;
  final int stationId;
  final String name;
  final String deviceKey;
  final String type;
  final bool isActive;
  final DateTime? lastSeen;
  final DateTime createdAt;
  final DateTime updatedAt;

  Device({
    required this.id,
    required this.stationId,
    required this.name,
    required this.deviceKey,
    required this.type,
    required this.isActive,
    this.lastSeen,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'].toString(),
      stationId: json['station_id'],
      name: json['name'] ?? '',
      deviceKey: json['device_key'] ?? '',
      type: json['type'] ?? '',
      isActive: json['is_active'] ?? false,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class RegisterDeviceResponse {
  final String message;
  final Device device;

  RegisterDeviceResponse({
    required this.message,
    required this.device,
  });

  factory RegisterDeviceResponse.fromJson(Map<String, dynamic> json) {
    return RegisterDeviceResponse(
      message: json['message'],
      device: Device.fromJson(json['device']),
    );
  }
}
