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
